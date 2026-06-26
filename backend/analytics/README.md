# Consolidated BI — CDS analytical queries

The surviving reports from [`docs/BI-CONSOLIDATION.md`](../../docs/BI-CONSOLIDATION.md)
built as **CDS analytical queries**: each is an analytical **cube**
(`@Analytics.dataCategory: #CUBE`) over its real Z-table plus a **query**
(`@Analytics.query: true`). Read-only — no behavior. The variants that used to be
separate Z reports are now **dimensions** on one query (slice/drill instead of a
new program).

Consume each query in the **Query Browser** / an **Analytical List Page** /
Design Studio, or expose it through the external BI tool.

| Query (`ZC_*Query`) | Cube table | Replaces |
|---|---|---|
| `ZC_PackedStockQuery` | `ZPP_PACK` | ZBOXSTOCK, ZGSTOCK, ZPRP1, ZSSTOCK, ZDSTOCK, ZSTOCK, ZPRP, ZPRPSZ (8) |
| `ZC_PackingRegisterQuery` | `ZPP_PACK` | ZPLIST01–03(+A/T/N/D), ZPACKLIST(01/N) (17) |
| `ZC_WipBatchQuery` | `ZPP_BATCHN` | ZBATCH_WIP |
| `ZC_HuInventoryQuery` | `ZHUINV_ITEM` | ZHUINV_CLS, ZHUMO, ZHUREC (3) |
| `ZC_PendingContractQuery` | `ZPP_SCHEDULEN` | ZPCON, ZPCOND, ZPCONS (ZPCON_CP dropped) |
| `ZC_ExportRegisterQuery` | `ZEXP` | ZGCUDB + export side of ZBRC/ZEXP |
| `ZC_MergeAnalysisQuery` | `ZPP_MERGE` | merge slice of the stock reports |
| `ZC_RecipeAnalysisQuery` | `ZPP_RECEIPE` | ZRECPM |
| `ZC_JobCardQuery` | `ZPP_JOBN` | ZJOBREPTN (ZJOBREPORT retired) |
| `ZC_DispatchRegisterQuery` | `ZSOL_HUDISPATCH` | ZPWDIS, ZDISPATCH, ZPDESP |
| `ZC_GstTaxQuery` | `ZSOL_GST_DET` | ZGST, ZGST1, ZGST2, ZGSTCR (or standard GST/DRC) |

> `ZC_PackedStockQuery` and `ZC_PackingRegisterQuery` share **one** cube
> `ZI_PackedStockCube` (both over `ZPP_PACK` — audit P4, one cube many queries),
> so it's **11 queries over 10 cubes**.

> **11 queries replace ~40 Z reports.** The rest of the 87 are dropped
> (dead/duplicate), routed to **standard** inventory/AR/AP apps, or covered by
> already-built transactional apps — see the consolidation doc.

## Pattern per query
- `zi_<name>.ddls.asddls` — `ZI_*Cube`: dimensions + `@DefaultAggregation: #SUM`
  measures (+ a synthetic `RecordCount`).
- `zc_<name>.ddls.asddls` — `ZC_*Query`: dimensions on `#ROWS`/`#FREE`, measures on
  `#COLUMNS`.

## Wiring / verify before activating
- **Joins:** cubes are modelled over the **primary** table for accuracy. Where a
  report needed values from another object (e.g. GST tax amounts from billing,
  dispatch weight from `ZPP_PACK`, contract value from `ZVBAP`), add an
  association to that cube/dimension — marked as the next wiring step.
- **Units:** weight measures on `ZPP_PACK` have no single UoM column (kg implied);
  add a unit/currency reference where your data requires it.
- **Authorization:** switch `#NOT_REQUIRED` to `#CHECK` + a DCL access control
  before production.
- **Counts:** `RecordCount` gives box/item/record counts for every query.

## Create in ADT
No DB tables to create (cubes read existing Z-tables). Optionally add an OData V4
analytical service binding per query for an Analytical List Page; for the Query
Browser no binding is needed.

## Branch
Tracked on `claude/fiori-app-extensions-h1nb64`.
