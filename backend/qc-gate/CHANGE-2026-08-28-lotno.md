# 2026-08-28 — the greige lot resolution was built on a field that stopped being a lot in 2013

## What prompted it

The open question was where the greige inspection lot should sit: on the
supplier batch (type 01 at goods receipt) or on the production lot (type 08 at
the 301 transfer). The answer given was the production lot. Checking that
against the data before building it showed the production lot does not exist.

## The finding

`ZPP_BATCHN-LOTNO` was a real greige lot number until roughly mid-2013. The
plant then stopped filling it in and has written the yarn quality into it ever
since. Grouped by material and dated, the field splits cleanly:

`T155072BTSSNXXXXXX`

| LOTNO | rows | first | last |
|---|---|---|---|
| `P-295`   | 312 | 2012-10-24 | 2013-04-15 |
| `5-2251T` | 147 | 2012-09-06 | 2012-11-12 |
| `5D-506`  |  90 | 2012-11-20 | 2013-03-10 |
| **`BRT`** | **15,096** | **2002-02-13** | **2026-03-25** |

`T150048SDSSNXXXXXX` matches: 68 real lots confined to 2012–13, then `TEX` for
7,299 rows to last month. Plant-wide, 410 distinct values over 131,562 rows,
nine of them covering ~115,000.

Three further constraints found while checking:

- The 301 transfer **pools** stock rather than renaming a lot. `DRM1` holds 745
  batch rows of genuine supplier lots (`AT1-5364`, `AT/3-5006L`); `DPR1` holds
  **33**, all yarn qualities (`TPM` across 25 materials, `TEX` 23, `BCT` 12),
  including `" TPM"` and `" TEX"` with leading spaces.
- `MSEG-AUFNR` is blank on every 301, so the movement records no order.
- Type 08 lots carry no `MBLNR`, `EBELN` or `LIFNR` and cannot be traced back
  to what created them.
- `ZPP_BATCHN-CLOSED` is set on **7 rows out of 131,562**, so "not closed"
  filters nothing.

## Decision

The greige inspection lot sits on the **supplier batch in `DRM1`, inspection
type 01 at goods receipt** — the only identifier in this system that describes
real yarn. The order is not auto-resolved from a recorded link, because no such
link exists.

`LOTNO` is exposed as `GreigeLotRef`: displayed, never resolved on. Not renamed
`YarnType`, which would be wrong for the 2012–13 rows where it really is a lot.

## What changed in KSD (all active, transport KSDK906754)

| Object | Change |
|---|---|
| `ZI_QC_BATCH_JOB` | `GreigeLot` → `GreigeLotRef` |
| `ZI_QC_BATCH_BY_NO` | `GreigeLot` → `GreigeLotRef` |
| `ZI_QC_BATCH_BY_GREIGE` | rekeyed from `LOTNO` to `GreigeMaterial`; 365-day window; now answers "which orders recently consumed this material" |
| `ZI_QC_ORDER_CONTEXT` | `GreigeLotCount` → `GreigeLotRefCount` |
| `ZI_QC_LOT_ORDER` | greige branch removed; `ProductionLot` now `ZPP_BATCHN-BATCHNO`; `GreigeLot` = `QALS-CHARG` on types 01/08, blank otherwise; new `OrderSource 'M'`; new `GreigeOrderCount` |
| `ZI_QC_INSP_LOT` | propagated; new `GreigeLotRef`, `GreigeOrderCount` |
| `ZC_QC_INSP_LOT` | labels corrected; `GreigeLotRef` exposed as "Lot Ref. (legacy)" |

### OrderSource values

- `O` — the lot carries the order itself (in-process, types 03/04)
- `B` — `QALS-CHARG` matched a plant batch number
- `M` — the lot's greige material has exactly one order in the last 365 days,
  so the order is settled **by elimination**. An inference, not a record.
- ` ` — operator picks

## Activation order (SAP blocks on dependents, so this order matters)

SAP refuses to activate a view while a dependent still references a removed
field, so the rename ran top-down with temporary aliases:

1. `ZI_QC_BATCH_JOB` exposing **both** `GreigeLotRef` and `GreigeLot`
2. `ZI_QC_LOT_ORDER` — drop the `bg` join and every `bn.GreigeLot` read
3. `ZI_QC_BATCH_BY_NO`, then `ZI_QC_ORDER_CONTEXT` (also dual-aliased)
4. `ZI_QC_BATCH_BY_GREIGE` — now unreferenced, so free to rekey
5. `ZI_QC_LOT_ORDER` again — add `bg` back on material, add `GreigeLotRef`
6. `ZC_QC_INSP_LOT`, then `ZI_QC_INSP_LOT`
7. Drop both temporary aliases

Note: CDS rejects an `IN` list inside `CASE WHEN` here — use `OR`.

## Verification

- `ZI_QC_INSP_LOT` returns **151** rows, matching `QALS`. No multiplication.
- `sap_inactive_objects` returns 0.
- `ZI_QC_BATCH_BY_GREIGE` for plant 2002:

| Greige material | Orders | Batches | Behaviour |
|---|---|---|---|
| `T1505T34TXXTEST` | 7 | 13 | operator picks |
| `T11072BCXXXXXXXXXX` | 1 | 3 | settled by elimination |
| `T300962NYLONDYEDXX` | 1 | 4 | settled by elimination |
| `T150048SDSSNXXXXXX` | 1 | 1 | settled by elimination |
| `T155072BTSSNXXXXXX` | 1 | 1 | settled by elimination |

Still untested against a real greige inspection lot, because plant 2002 has
none. Correct by construction, not by trial.

## App changes (all three, committed to Desktop/Fiori-Apps)

- **Break fixed:** all three `Detail.controller.js` had `$select` and filters
  reading `GreigeLot` from the `OrderBatch` entity (`ZI_QC_BATCH_JOB`), which no
  longer has that field. Those requests would have returned 400. Repointed to
  `GreigeLotRef`. The `oCtx.getProperty("GreigeLot")` reads, which are on the
  inspection lot and still valid, were deliberately left alone.
- Post-dyeing and post-winding worklists bound `{GreigeLot}`, now blank on
  types 03/04 by design. Rebound to `{GreigeLotRef}`, column relabelled
  "Lot ref.".
- `qc-raw-material` picker labels corrected: it fills the 301's destination
  batch, which under current practice is the yarn-quality bucket, not a lot.
- `_loadIncoming` in both in-process apps is now **inert** and documented as
  such. It was wired on the belief that `GreigeLot` resolves through `LOTNO`.
  Its guard returns immediately. Left in place as the hook for the day the
  greige-to-batch link is actually recorded.

## Roadmap, not done

Making `DPR1` carry the supplier lot (or `ZPP_BATCHN-BATCHNO`) instead of the
yarn quality would restore end-to-end traceability and make type 08 viable.
That changes how the floor issues material and breaks with 13 years of
convention — a deliberate project, not a step in a QC build.

---

## Deployed and verified in the running system, 2026-08-28

Deployed to KSD under `KSDK906754`. The BSP upload registers as `LIMU WAPP`
(one entry per file), **not** `R3TR WAPA` — an earlier check looked for the
wrong object type and wrongly reported the deploy as not having run. The apps
landed in two tasks under the same request: `KSDK906755` (MD) and
`KSDK906756` (FIORI_USER, created by the upload itself).

**Release note:** SAP will not release `KSDK906754` while `KSDK906756` is open,
and that task belongs to `FIORI_USER`. Ownership will have to be taken in SE01
or Basis asked to release it.

`KSDK906696`, which these apps last shipped on, was released 2026-08-21 — which
is why deploy validation demanded a transport. All three `ui5-deploy.yaml`
files now pin `KSDK906754`, deliberately the same request as the CDS changes,
so the rename and the app fix import into KSQ together.

### The type 01 branch, confirmed on real data

Plant 2002 still has no greige inspection lot, but clearing the plant filter
surfaced one in plant 7000 that exercises the same code path:

```
Plant 7000 · type 01 · PTDB57280G900RED
Batch            TE213
GreigeLot        TE213     <- CASE fills it for types 01/08
ProductionLot    (blank)   -> UI shows "not assigned yet"
GreigeLotRef     (blank)   <- no plant batch record, so no LOTNO
OrderSource      ' '       <- nothing resolved, and it says so
GreigeOrderCount 0
```

Every field behaves as specified. `GreigeLot` takes `QALS-CHARG` because it is
a goods-receipt lot; `ProductionLot` stays blank rather than echoing the batch
back; `OrderSource` reports no resolution instead of inventing one.

Caveat: `PTDB57280G900RED` is a paper tube, not yarn. It appears because Grey
QC scopes on inspection TYPE (01 and 08), not on material. With the Plant
filter set to 2002 this does not arise, and once type 01 is active only on the
greige materials the scoping is natural. No material filter was added - the
plant field already does the job, and hard-coding a material group would be
guessing at the catalogue.

### Worklists confirmed rendering

| App | Columns | Rows in 2002 |
|---|---|---|
| Raw Material QC | Supplier Lot, **Greige lot**, **Production lot**, Material, ... | 0 |
| Post-Winding QC | Batch, Plant batch, **Lot ref.**, Material, Order, ... | 0 |
| Post-Dyeing QC | Batch, Plant batch, **Lot ref.**, Shade/Dyed Material, Order, ... | 0 |

Zero rows in plant 2002 is the expected pass: the metadata resolves and nothing
returns 400.

### Note for the next deploy

UI5 bundles every view into `Component-preload.js`, so a normal browser reload
keeps rendering the old build even after a successful upload. Use DevTools ->
Network -> Disable cache, or append `&sap-ui-xx-componentPreload=off`. Fetching
a view XML directly from the server distinguishes a stale client from a failed
upload.

### Still not tested

The Detail view and the greige lot picker. `_openGreigeLotPicker` holds the
`$select` repointed to `GreigeLotRef`, and it only fires when a lot is opened
and the release dialog reached. The worklists prove the projection and the
metadata, not that path.
