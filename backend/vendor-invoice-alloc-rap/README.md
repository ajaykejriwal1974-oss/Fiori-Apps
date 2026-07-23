# Vendor Invoice Allocation (ZVFORM/ZVFORMS) — managed RAP backend

Phase 2. Clean-core Fiori replacement for transactions **`ZVFORM`** (vendor invoice,
`ZSOL_VFORM1`) and **`ZVFORMS`** (allocate vendor invoice, `ZSOL_VFORM`). Both are
driven by the legacy table **`ZVFORM2`** ("ztable for cform") — the vendor-side twin
of `ZCFORM1` behind [`cform-master`](../cform-master-rap), so this reuses the same
class-free managed-master pattern (single flat entity, no composition).

Maintain vendor invoices and their **C-Form / value allocation** (`ALLOCATED_VALUE1`,
`UN_ALLOT_VAL`, `ALLOCATE_CHK`) in one worklist.

## Objects (package ZKGPL_FIORI)
| Object | Type |
|---|---|
| `ZI_VFORM` / `ZC_VFORM` | CDS interface + projection |
| `ZI_VFORM` / `ZC_VFORM` behavior | managed (class-free) + projection behavior |
| `ZC_VFORM` metadata ext | UI annotations |
| `ZUI_VFORM` | service definition |
| `ZUI_VFORM_04` | OData V4 UI binding (publish via /IWFND/V4_ADMIN) |

## Design notes
- **Managed, non-draft, class-free** (`managed;`, no `strict`, no `authorization`) —
  same shape as `ZI_ACCGRP` / `ZI_RECIPE` (the proven fleet pattern).
- Amount fields (`InvoiceValue`, `AllocatedValue`, `UnallocatedValue`, `FormValue`)
  are exposed as plain values — `ZVFORM2` carries no currency key (as cform-master).
- The **allocate** step (`ZVFORMS`) is modelled as editable fields
  (`AllocatedValue`/`UnallocatedValue`/`AllocatedFlag`); a guided `allocate` action
  can be added later if wanted.
- `ZVFORM` also reads `ZKIL_VBRK` (billing append) + `ZZGATEPASS` for enrichment —
  read-side only, add as associations later if the screen needs that context.
- **VERIFY at activation:** field names/types are from the dictionary export; the
  first activation on KSD confirms them against the live `ZVFORM2` (esp. the key —
  taken as `INVOICE_NO` — and the CURR fields' currency reference).

## Deploy — via abapGit
Staged in [`backend/_abapgit_import/src/`](../_abapgit_import). Pull the repo into
`ZKGPL_FIORI`, activate, create binding `ZUI_VFORM_04` + publish, deploy the FE app
[`apps/vendor-invoice-alloc`](../../apps/vendor-invoice-alloc), add the FLP tile
(semantic object `VendorInvoiceAlloc`, action `manage`).

## Retires
`ZVFORM`, `ZVFORMS` (2 tcodes). `ZVK11` routes to standard condition upload — see
[`docs/PHASE2_SCOPE.md`](../../docs/PHASE2_SCOPE.md).

Status: **scaffolded + staged for abapGit pull, not yet deployed.**
