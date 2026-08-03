# Performance audit — Fiori apps + RAP backend

Guiding principle (the Sensibull model): batch and compute on the server; keep the client to
rendering and one round trip per user action — never one request per row/cell/keystroke.

## Fixed in this branch

1. **Mass-edit QM app: N PATCHes → one real batch** (`record-inspection-results-mass`).
   The model inherited `updateGroupId` from `$auto`, so every edited cell auto-submitted its
   own PATCH and the "post all in one round trip" `submitBatch("$auto")` was a no-op — a
   300-characteristic mass entry was 300 sequential round trips. Now a deferred
   `updateGroupId: "massEdit"` accumulates edits client-side and `submitBatch("massEdit")`
   sends ONE $batch. Rebinding with new filters discards unsent edits
   (`resetChanges("massEdit")`) so stale PATCHes can't ride along with a later post.

2. **Explicit `$select` on the three control-less `bindList` reads**
   (`contract-batch-update`, `dyeing-packing`, `post-goods-movement-hu`).
   `autoExpandSelect` derives `$select` from *control* bindings; a programmatic binding has
   none, so these requests returned every property of every row while the controllers used
   5–7 fields. Field lists verified against the CDS projections (`ZC_Contract_Item`,
   `ZC_Packing_Unit`, `ZC_HU_Item`).

3. **O(1) duplicate-HU lookup on the scan-gun path** (`post-goods-movement-hu`).
   `_huAlreadyAdded` scanned the whole `/items` array per scan (O(n²) over a shift); now a
   hash set, kept in sync on add/remove/clear/post.

4. **Per-keystroke full-array recompute → on-blur** (`contract-batch-update`,
   `dyeing-packing`): `liveChange` → `change` on the four grid inputs whose handlers
   rescan/re-sum the entire loaded array.

5. **`sap.f` removed from 10 manifests** — declared, preloaded, never used (zero references
   in any view). One whole library off the critical path per app.

6. **`earlyRequests: true` added to the 3 manifests missing it** — removes a serialized
   `$metadata` round trip at startup (the other 9 apps already had it).

## Fixed in batch 3 (ABAP)

- **F3 — `zcl_obd_automation`**: the per-sales-order `SELECT` inside the loop (classic N+1)
  is now ONE read grouped in memory (`GROUP BY` loop). The unused `iv_werks` is surfaced in
  the job log (the dispatch table has no plant column — the restriction must be wired into
  the delivery-API step when implemented, and until then a plant-restricted job is never
  SILENTLY unrestricted).
- **F8 — `zcl_po_automation`**: the VBRK⋈VBRP scan is bounded by a billing-date window
  (`iv_lookback`, default 90 days) — it previously scanned and materialised the sales org's
  ENTIRE billing history on every run, growing forever.
- **F9 — `zi_dispatch_box`**: the `zpp_pack` join now goes through a new
  `ZI_PackLatestYear` helper (latest GJAHR per box) — a bare BOXNO join fanned each dispatch
  row out once per fiscal year and collided the declared `key boxno` (OData key collision).
- **F5 (correctness) — `lt_return` hygiene across ALL BAPI loops**: `CLEAR` before every
  call + an explicit error accumulator where calls repeat per item
  (`packing-detail` ×2, `hu-unpack`, `palletization`, `packing-hu`), and one-line CLEARs in
  `batch-status`, `hu-inbound`, `post-packing-gr`, `sales-doc-status`. Without this, item
  1's error poisoned every later item's check — and in `updatePendingRate` a second key
  would have RESENT the previous contract's price conditions (`lt_cond`/`lt_condx` also
  cleared). `packing-hu` additionally cleared its `lv_prev_hu` chain state, which carried
  the HU hierarchy across action keys.

## Fixed in batch 4

- **F2 — `_Item` compositions for the flat mass actions** (`batch-status`: closeBatch /
  deleteBatch via new `ZD_BatchCloseItem`/`ZD_BatchDeleteItem`; `mtos-process`:
  convertToMts via new `ZD_MtoMtsItem`). The worklists' whole selection now travels in ONE
  call with ONE commit — closeBatch counts successes and names not-found batches;
  deleteBatch is all-or-nothing; convertToMts puts every stock line into ONE
  `BAPI_GOODSMVT_CREATE` → one 411-E material document. (Was: one HTTP round trip + one
  synchronous `COMMIT WORK` per selected row.)
- **F14 — Action payloads projected to contract fields** in all eight worklist controllers
  (`ITEM_PROJECT` per action): no more `@odata.etag`/`@$ui5.*` annotations or unused
  columns in `_Item` — and the palletization mapping sends `HandlingUnit` (the contract
  field) instead of the row key `Pallet`, fixing a guaranteed 400 on activation.
- **F10 — `WorkCenterInternalID` exposed** (`zi/zc_qm_inspectionchar` ← `oper.arbid`); a
  numeric filter entry hits the base-table column directly instead of pre-joining the whole
  open-characteristics set through the `_WorkCenter` association (name entry still filters
  by name for usability).
- **F15 — UI5 bootstrap is relative** (`resources/sap-ui-core.js`) in all 12 apps — served
  by the ABAP system / ui5 tooling instead of a cross-origin public-CDN fetch that fails
  behind an on-prem firewall.
- **mtos-process `lt_return`/`lt_docs` CLEARs** (missed by the batch-3 sweep — same
  carry-across-keys class of bug).

## Remaining findings (ranked, not yet implemented — ABAP/design changes)

- **F4 — `SELECT`/commit inside `LOOP AT keys` in `zbp_i_sales_doc_status`** (the documented
  "mass close" path): hoist with `FOR ALL ENTRIES`, commit once.
- **F5 (rest) — Per-item BAPI calls where table interfaces exist** (`packing-detail`,
  `hu-unpack`, `palletization`, `packing-hu`, `qm-mass-results`) — batch into one call where
  the FM accepts a table. (The lt_return correctness half of this finding is fixed above.)
- **F6 — Eight worklists bind an entire entity set unfiltered** (`/Batch`→MCHA,
  `/Pallet`→VEKP, …) with `$count` on first paint and no FilterBar anywhere. Add filter bars
  with suspended bindings + mandatory plant/date selection parameters on the CDS views.
  This decides whether the apps are usable against production-sized tables at all.
