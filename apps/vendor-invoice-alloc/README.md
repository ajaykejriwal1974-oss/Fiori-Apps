# Vendor Invoice Allocation (ZVFORM/ZVFORMS) — custom Fiori Elements app

**Status: LIVE on KSD (client 500)** — Phase 2, 23 Jul 2026. Backend RAP active,
`ZUI_VFORM_04` published, app deployed, renders the List Report in the FLP.
(`ZVFORM2` is currently empty — 0 rows — so the list shows "No data found"; the
app is fully functional, awaiting data / Create.)

Fiori Elements List Report + Object Page app, the clean-core replacement for
transactions **`ZVFORM`** (vendor invoice) and **`ZVFORMS`** (allocate vendor
invoice). Built on the proven class-free managed-master pattern (same as Account
Grouping / C-Form).

Binds the OData V4 service of
[`backend/vendor-invoice-alloc-rap`](../../backend/vendor-invoice-alloc-rap)
(`VendorInvoice` entity), service binding `ZUI_VFORM_04`.

## What you maintain
Vendor invoices from `ZVFORM2` — invoice/supplier/purchasing-doc details plus the
**C-Form / value allocation** (`AllocatedValue`, `UnallocatedValue`, `AllocatedFlag`,
form no./date/value). The "allocate" step is editable fields on the Object Page.

## Deploy
1. abapGit **Pull** the repo into `ZKGPL_FIORI` → activate (`ZI_VFORM`, `ZC_VFORM`,
   behaviors, DDLX, `ZUI_VFORM`).
2. Service binding `ZUI_VFORM_04` (OData V4 - UI) on `ZUI_VFORM` → Activate → Publish.
3. Deploy this app:
   ```bash
   cd apps/vendor-invoice-alloc
   FIORI_TOOLS_USER=MD FIORI_TOOLS_PASSWORD='<pw>' npx fiori deploy --yes --config ui5-deploy.yaml
   ```
   (app `ZVFORM_APP`, package `ZKGPL_FIORI`, transport `KSDK906624`)
4. FLP tile — semantic object `VendorInvoiceAlloc`, action `manage`.

Prereq: activate the backend + publish `ZUI_VFORM_04` first (see backend README).
