# Phase 2 — Core transactional gap (scope)

Reconciled scope, 23 Jul 2026. Phase 1 delivered the Packing List app (earlier),
Account Grouping master (LIVE) and the Credit/Debit query. Phase 2 is small — the
build-plan flagged it as "~1 week, 3 tcodes", and the reconciliation holds:
**one app to build + one route-to-standard.**

## 1. Vendor Invoice Allocation app — BUILD (C-Form pattern)

Replaces **`ZVFORM`** (`ZSOL_VFORM1`, "vendor invoice") and **`ZVFORMS`**
(`ZSOL_VFORM`, "allocate vendor invoice"). Both are driven by the legacy table
**`ZVFORM2`** — described in the dictionary as *"ztable for cform"*, i.e. the
vendor-side twin of `ZCFORM1` behind the already-built
[`cform-master`](../backend/cform-master-rap). So this is the **same managed-RAP
master pattern**, now proven twice (C-Form + Account Grouping).

### Persistence — `ZVFORM2` (existing table, do NOT create)
| Field | Key | Type | BO field |
|---|---|---|---|
| `INVOICE_NO`       | ✔ | CHAR 10 (BELNR_D) | InvoiceNumber |
| `PURCHASE_DOC`     |   | CHAR 10 (EBELN)   | PurchasingDocument |
| `REFERENCE_NO`     |   | CHAR 16 (XBLNR)   | ReferenceNumber |
| `INVOICE_DT`       |   | DATS              | InvoiceDate |
| `INVOICE_VAL`      |   | CURR              | InvoiceValue |
| `ALLOCATED_VALUE1` |   | CURR              | AllocatedValue |
| `UN_ALLOT_VAL`     |   | CURR              | UnallocatedValue |
| `VEND_CODE`        |   | CHAR 10 (LIFNR)   | Supplier |
| `VEND_NAME`        |   | CHAR 35           | SupplierName |
| `FORM_TYPE`/`FRM_TYP` | | CHAR 2         | FormType |
| `FORM_NO`          |   | CHAR 20           | FormNumber |
| `FORM_DT`          |   | DATS              | FormDate |
| `FORM_VAL`         |   | CURR              | FormValue |
| `ALLOCATE_CHK`     |   | CHAR 1 (AUREF)    | AllocatedFlag |
| `QTY`              |   | QUAN              | Quantity |
| `CURRIER_NAME` / `CURRIER_DETAIL` | | CHAR 25 | Courier / CourierDetail |

- **Single flat entity** (no composition) → simplest managed-RAP master, class-free
  `managed;` non-strict (as Account Grouping / the master fleet).
- The **allocate** step (`ZVFORMS`) = maintain `ALLOCATED_VALUE1` / `UN_ALLOT_VAL` /
  `ALLOCATE_CHK`; model it as plain edit fields first, or a small `allocate` action
  later if a guided flow is wanted.
- `ZVFORM` also reads `ZKIL_VBRK` (billing append) and `ZZGATEPASS` for enrichment —
  read-side only; the persistence is `ZVFORM2`. Add those as associations later if
  the screen needs billing/gate-pass context.

### Deliverables
- `backend/vendor-invoice-alloc-rap` — CDS interface/projection, class-free managed
  behavior over `ZVFORM2`, DDLX, service def `ZUI_VFORM`; stage in `_abapgit_import`.
- `apps/vendor-invoice-alloc` — FE List Report / Object Page (clone `account-grouping`).
- Binding `ZUI_VFORM_04` + publish; FLP tile (semantic object `VendorInvoiceAlloc`,
  action `manage`).
- Retires `ZVFORM`, `ZVFORMS` (2 tcodes).

## 2. ZVK11 — route to STANDARD (no build)

`ZVK11` (`ZPRG_BDC_VK11`, "Upload Create Condition Records", table `ZKOMPAZ`) is a
**BDC upload of pricing condition records**. That is standard SAP:
- **Set / Manage Prices** Fiori apps, or classic `VK11`/`VK12`.
- Mass creation via the standard condition-upload tooling (e.g. price-list upload,
  or the Migration Cockpit for initial loads).

No custom RAP object — the BDC program is replaced by standard condition maintenance.
VERIFY the exact condition types/tables `ZKOMPAZ` fed, then point users at the
matching standard app. (Consistent with the Phase 1 route-to-standard bucket.)

## Effort
~1 week: one master app on a proven pattern + a routing decision. After Phase 2,
the only remaining custom transactional gap is closed; Phases 3–5 are analytics,
DRC adoption, and migration/retire (see the build plan).
