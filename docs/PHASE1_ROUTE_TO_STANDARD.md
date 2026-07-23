# Phase 1 — route-to-standard mapping (no custom build)

Reconciled Phase 1 scope, 23 Jul 2026. The build-plan PDF's Phase 1 was written
before the field-dictionary re-classification; several "quick-win apps" turned out to
have **no custom Z-table** and are better met by **standard SAP** (clean core). This
doc records the route for each. Only two Phase-1 items are genuinely built:
**Account Grouping** (`ZSOL_ACCGRP`, real Z-tables → `apps/account-grouping`) and the
**Credit/Debit Note** query (`backend/analytics/ZC_CRDR_NOTE`).

## Route-to-standard items

| Z-tcode | What it was | Standard target | Stub |
|---|---|---|---|
| `ZMINMAX` | Min/Max stock levels | Material master MRP views (`MARC-MINBE/MABST/EISBE`) via **Manage Material Master** / `MM02` / **Mass Maintenance of Materials**; yarn attributes (`ZZMARA`) stay key-user custom fields | `backend/minmax-master-rap` |
| `ZBOE` | Bill of Exchange | Standard FI special-G/L B/E (`F-36`/`FBW1`/`F-33`/`FBW4` …); **Manage Customer/Supplier Line Items**, **Post General Journal Entries** | `backend/bill-of-exchange-std` |
| `ZEXN` | Custom/Export invoice number | Billing number range (`VOFA`/`RV_BELEG`) or Official Document Numbering; **Manage Billing Documents** | `backend/custom-invoice-no-std` |
| `ZINSPLOT` | Inspection-lot maintenance | **Manage Inspection Lots** / `QA32` / `QA02`; **Make Usage Decision**; mass results via built `record-inspection-results-mass` | `backend/inspection-lot-std` |
| `ZPR` | Purchase requisition | **Manage Purchase Requisitions** / **My Purchase Requisitions** (`ME51N` family) | — |
| `ZPOCLOSE`, `ZPO_CLOSE` | PO close (really an action) | **Manage Purchase Orders** (delivery/final-invoice/"closed" flags); or the EXT action pattern | — |
| `ZRFQ` | Request for quotation | **Manage RFQs** / **Manage Supplier Quotations** (`ME41` family) | — |
| `ZQAR` | Inspection lot / QM report | **Manage Inspection Lots** / **Results Recording** (same as ZINSPLOT) | — |
| `ZPDF` | Print / output | Standard **output management** (BRF+ / Adobe forms) — print stays classic by decision | — |
| `ZSOL_AUTOPAY` | Automatic payments | **Manage Automatic Payments** / `F110` (Automatic Payment Program) | — |

## Why route instead of rebuild
Each of the above either has **no custom persistence** (nothing to migrate) or
duplicates data/logic SAP already delivers and maintains (MRP, FI special-G/L, QM
inspection lots, MM purchasing, APP). Rebuilding them as custom Fiori apps would
re-introduce exactly the clean-core debt this programme is retiring. Where a focused
screen is still wanted, prefer a **key-user / adaptation** restriction of the standard
app over a new BO + table.

## Action for KSD
For the routing items, the work is **FLP content + a little config**, not code:
1. Add the standard Fiori tiles to the relevant business-role catalogs/spaces.
2. VERIFY the couple of ambiguous ones (`ZEXN` customs-vs-ODN; confirm `ZPOCLOSE`
   is fully covered by standard PO flags vs needs the EXT close action).
3. Retire the Z-tcodes once users are trained on the standard tiles.
