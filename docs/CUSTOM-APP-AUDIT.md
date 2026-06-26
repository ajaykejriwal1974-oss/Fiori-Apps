# Custom & extended apps — duplication / consolidation audit

A review of everything built in this repo (17 apps + ~28 RAP backends + 11 BI
queries + 2 automation classes) for overlap. Three real consolidations found;
the rest is genuinely distinct.

> **✅ All applied.** P1 → `backend/mtos-process-rap` + `apps/mtos-process`
> (2 services + 2 apps → 1 + 1). P2 → `backend/sales-doc-status-rap`
> (2 services → 1). P3 → `backend/hu-shared` shared bases consumed by 7 HU
> services (8 duplicate reads → 2 shared). **P4** (follow-up scan) → the two BI
> cubes over `ZPP_PACK` merged into one `ZI_PackedStockCube` feeding both queries
> (one cube, many queries). Net: **−3 services, −1 app, −1 BI cube, one HU read
> model**; no coverage lost.

## Follow-up scan (post-merge) — clean
- **Object names** — every CDS view / behavior / service / class / abstract
  entity name is **globally unique** across the repo (no activation collision
  from the merges).
- **P4 — two `ZPP_PACK` cubes merged** (only same-table BI pair): packed-stock +
  packing-register now share one cube with both dimension sets.
- **Action result structures** — several tiny `ZD_*Result` entities share a shape
  (`{Message}` ×4, `{MaterialDocument, Message}` ×3). **Left as-is on purpose**:
  per-action result types are idiomatic RAP and self-documenting; a shared
  generic result would couple unrelated actions for ~5 saved lines. Not worth it.
- Everything else (11 masters, the other 10 BI cubes, the 2 automation classes,
  contract-batch vs status, dispatch-correction vs obd-automation vs the BI
  dispatch query) is genuinely distinct — confirmed, no further merges.

## P1 — Merge `mto-mts-transfer-rap` + `hu-phys-inventory-rap` ⭐ (verified)
**Both are the same legacy program `ZSOL_MTOS_PROCESS`.** `ZMTOS` ("Transfer MTO
to MTS stock") and `ZHUINV` ("Physical inventory document create") are two steps
of **one** flow — transferring make-to-order stock to make-to-stock *creates* the
phys-inv document.

| Today | Recommended |
|---|---|
| `backend/mto-mts-transfer-rap` (`convertToMts`) | **`backend/mtos-process-rap`** — one service over the MTO-stock read |
| `backend/hu-phys-inventory-rap` (`createPhysInvDoc`) | model exposing **both** actions `convertToMts` + `createPhysInvDoc` |
| `apps/mto-mts-transfer` + `apps/hu-physical-inventory` | one *MTOS Process* app with both actions |

**Effect:** 2 services + 2 apps → 1 + 1. Low risk (both are thin scaffolds).

## P2 — Merge `contract-status-rap` + `sales-order-status-rap` (verified)
Identical read model — both `select from vbak`, differing only by
`where vbtyp = 'G'` (contract) vs `'C'` (order). The actions differ but the BO is
the same sales document.

| Today | Recommended |
|---|---|
| `ZI_SalesContract` (VBAK, G) — close/complete/release/updateRate | **`ZI_SalesDocStatus`** over VBAK with `vbtyp` as a dimension; |
| `ZI_SalesOrderStatus` (VBAK, C) — closeSalesOrder/closeOrderProgram | expose **all** actions on one service `ZUI_SALESDOC_STATUS` |

Both adaptation apps (`manage-sales-contracts-ext`, `manage-sales-orders-ext`)
keep their own UI and call the merged side-service by document id — only the
`REPLACE_WITH_*_SERVICE` placeholder changes. **2 services → 1.**

## P3 — Share one HU read model across the 8 HU/packing services (low risk)
Eight services each define a **near-identical interface view over the standard HU
tables** (`VEKP` header / `VEPO` items): `packing-detail-rap`, `packing-hu-rap`,
`goods-movement-hu-rap`, `hu-inbound-rap`, `hu-phys-inventory-rap`,
`hu-unpack-rap`, `palletization-rap`, `post-packing-gr-rap`.

→ Introduce **one** shared interface `ZI_HU_Item` (HU / item / material / batch /
qty / unit / plant / storage location); each service's projection consumes it and
adds only its **own action(s)**. The 8 distinct apps/actions stay — we just delete
8 copies of the same `select from vekp/vepo`.

> `packing-detail-rap` (`ZPP_PACK_MODULE_NEW`, the `ZPACK01/02/03N` + `ZREPACK`
> family) and `packing-hu-rap` (`ZPP_PACK_MODULE_DYING`, the `ZPACK*D` dyeing
> family) are **different program families** — keep both, but they share `ZI_HU_Item`
> under P3 rather than each re-declaring the read.

## Genuinely distinct — do NOT merge
| Group | Why separate |
|---|---|
| 11 masters (recipe/job/schedule/transport/truck/merge/checked-by/packing-material/export/digi/cform) | distinct custom tables, distinct keys |
| 11 BI analytical queries | distinct cubes/dimensions (already consolidated from 87) |
| `po-automation` / `obd-automation` | different processes (PO vs delivery) |
| `contract-batch-rap` (VBAP batch update) vs `contract-status-rap` | batch assignment ≠ lifecycle status |
| `dispatch-correction-rap` vs `obd-automation` vs BI dispatch query | transactional vs automation vs analytics layer |
| `gate-pass-rap`, `qm-mass-results-rap`, `batch-status-rap` | unique objects / tables |
| `minmax-master-rap`, `bill-of-exchange-std` | reuse-standard stubs (no code) |

## Net if P1–P3 are applied
| | Before | After |
|---|--:|--:|
| RAP services (transactional) | 13 | **11** (−P1, −P2) |
| Freestyle CUS apps | 9 | **8** (−P1) |
| Duplicate HU read models | 8 | **1** shared (P3) |

No functional coverage lost — every tcode still maps to its action; the merges
remove duplicated *plumbing*, not capability.

## Recommendation
Apply **P1** first (clean, verified, low-risk), then **P3** (pure refactor, no UX
change), then **P2** (re-points two adaptation placeholders). All three are
mechanical and reversible.
