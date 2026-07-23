# Inspection Lot maintenance (ZINSPLOT) — reuse STANDARD, do not build

> **Re-classified (Phase 1 review).** `ZINSPLOT` ("Maintenance for Inspection lot")
> has **no program and no Z-table** in the dictionary (classification source = "—").
> Inspection lots are **standard QM objects** — clean-core **reuse**, not a rebuild.
> (This also overlaps the `ZQAR` route-to-standard already noted in the build plan.)

## What it really is
Inspection-lot data (status, usage decision, quantities, stock postings) is standard
Quality Management. Delivered apps/transactions (S/4HANA 2025):

| Need | Standard |
|---|---|
| Change inspection-lot data / stock | `QA02` — Change Inspection Lot |
| Record results | **Record Inspection Results** (Fiori) / `QE51N` — already covered by the built `record-inspection-results-mass` app |
| Usage decision & stock posting | **Make Usage Decision** (Fiori) / `QA11` |
| Worklist of lots | **Manage Inspection Lots** (Fiori) / `QA32` |

## Route — reuse standard
1. Use **Manage Inspection Lots** / `QA32` for the lot worklist and `QA02` for
   changes; **Make Usage Decision** for UD + stock.
2. Mass result recording is already handled by the custom
   [`record-inspection-results-mass`](../qm-mass-results-rap) app (BAPI-based).

> No custom RAP object or table is created for `ZINSPLOT`. Routing stub only (no
> `src/`). See [`docs/PHASE1_ROUTE_TO_STANDARD.md`](../../docs/PHASE1_ROUTE_TO_STANDARD.md).
