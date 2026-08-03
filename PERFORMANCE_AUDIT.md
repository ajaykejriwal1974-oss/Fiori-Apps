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

## Remaining findings (ranked, not yet implemented — ABAP/design changes)

- **F2 — Flat action parameters force one call per selected row** (`batch-status`,
  `mtos-process`). `ZD_Batch_Close/Delete` and `ZD_Mto_Mts` have no `_Item` composition, so
  the worklists' mass actions become N HTTP calls — each hitting a
  `BAPI_TRANSACTION_COMMIT wait = abap_true` **inside `LOOP AT keys`**. Add `_Item`
  compositions (the palletization pattern) and commit once after the loop.
- **F4 — `SELECT`/commit inside `LOOP AT keys` in `zbp_i_sales_doc_status`** (the documented
  "mass close" path): hoist with `FOR ALL ENTRIES`, commit once.
- **F5 (rest) — Per-item BAPI calls where table interfaces exist** (`packing-detail`,
  `hu-unpack`, `palletization`, `packing-hu`, `qm-mass-results`) — batch into one call where
  the FM accepts a table. (The lt_return correctness half of this finding is fixed above.)
- **F6 — Eight worklists bind an entire entity set unfiltered** (`/Batch`→MCHA,
  `/Pallet`→VEKP, …) with `$count` on first paint and no FilterBar anywhere. Add filter bars
  with suspended bindings + mandatory plant/date selection parameters on the CDS views.
  This decides whether the apps are usable against production-sized tables at all.
- **F10 — Filtering on `_WorkCenter` association** forces a pre-join of the whole open-
  characteristics set; expose `arbid` and filter on it, resolve the name for display only.
- **F14 — Worklist actions ship whole `getObject()` rows** (incl. `@odata.etag`/`@$ui5.*`)
  where the contract wants one field — and palletization sends `Pallet` where the action
  expects `HandlingUnit` (a guaranteed 400 once activated). Project down to contract fields.
- **F15 — Public-CDN UI5 bootstrap** (`https://ui5.sap.com/...`) in an on-prem landscape:
  use the ABAP-served runtime.
