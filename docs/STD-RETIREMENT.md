# STD retirement mapping — Z tcode → standard S/4HANA Fiori app + role

The **17 `STD` tcodes** in [CLASSIFICATION.md](CLASSIFICATION.md#std--use-standard-fiori-app--retire-the-z-program-17)
are already covered by standard S/4HANA 2025 apps. Nothing is built — for each
one you **assign the standard app via its business role, migrate any saved
variants/layouts, then retire the Z transaction and program**.

> Fiori app IDs are given where stable; the **classic transaction** is the
> reliable anchor (every Fiori app below also runs the same Customizing). Confirm
> each app is activated in your FES (`/UI2/FLPD_CUST`) and in the role's catalog.

## Production — Batch Master (6 tcodes → 1 standard app)
`ZBATCH01/02/03` and `ZBATCH01N/02/03N` are custom Create/Change/Display Batch
Master screens. They collapse into the **one** standard batch app (CRUD in a
single app, no separate create/change/display tiles).

| Z tcode | Z program | Action | Standard app (Fiori / classic) | Business role |
|---|---|---|---|---|
| ZBATCH01 / ZBATCH01N | SAPMZ_PP_BATCH(N) | Create batch | **Manage Batches** / `MSC1N` | `SAP_BR_WAREHOUSE_CLERK` |
| ZBATCH02 / ZBATCH02N | SAPMZ_PP_BATCH(N) | Change batch | **Manage Batches** / `MSC2N` | `SAP_BR_WAREHOUSE_CLERK` |
| ZBATCH03 / ZBATCH03N | SAPMZ_PP_BATCH(N) | Display batch | **Manage Batches** / `MSC3N`; **Batch Information Cockpit** (`BMBC`) | `SAP_BR_WAREHOUSE_CLERK` |

> The textile-specific batch attributes (shade, grade, denier…) are **batch
> classification characteristics** — maintain them on the standard batch via the
> classification tab / **Manage Batches**, reusing the existing characteristics.
> Any custom number range stays in the standard batch config.

## Finance — line-item display & documents (9 tcodes)
| Z tcode | Z program | Description | Standard app (Fiori / classic) | Business role |
|---|---|---|---|---|
| ZFBL3N | ZSOLS_FI_GL_LINE_DISP | G/L line item display | **Display Line Items in General Ledger** (F0706) / `FAGLL03` · `FBL3N` | `SAP_BR_GL_ACCOUNTANT` |
| ZZFBL3N | ZZFBLN3 | G/L account line items | **Display Line Items in General Ledger** (F0706) / `FAGLL03` | `SAP_BR_GL_ACCOUNTANT` |
| ZFBL5N | ZSOL_CUSTOMER_REPORT | Customer line items | **Manage Customer Line Items** (F0711) / `FBL5N` | `SAP_BR_AR_ACCOUNTANT` |
| ZZFBL5N | ZZFBL5N | Customer line item display | **Manage Customer Line Items** (F0711) / `FBL5N` | `SAP_BR_AR_ACCOUNTANT` |
| ZFB03 | ZCRPT_FI_R003 | Print voucher / display document | **Manage Journal Entries** (F0717A) / `FB03`; voucher via Output Management | `SAP_BR_GL_ACCOUNTANT` |
| ZCRDRNOTE | ZCRPT_FI_R001 | Credit / debit note | **Manage Credit Memo Requests** (F0696) / `VA01` (G2/L2); print via Output Mgmt | `SAP_BR_BILLING_CLERK` |
| ZF90 | ZRPT_FI_BDC_F90 | Asset acquisition (purchase) | **Post Asset Acquisition** / `F-90` (`ABZON`) | `SAP_BR_AA_ACCOUNTANT` |
| ZFF67 | ZCBDC_FI_FF67_N1 | Manual account statement | **Manual Bank Statement** / `FF67`; **Reprocess Bank Statement Items** (F1681) | `SAP_BR_CASH_SPECIALIST` |
| ZCM_RELEASE | ZSOL_REMOVE_CREDITBLOCK | Credit release | **Manage Documented Credit Decisions** (F0717) / `UKM_CASE`; **Release Blocked Sales Orders** `VKM3` | `SAP_BR_CREDIT_CONTROLLER` |

## Materials Management (2 tcodes)
| Z tcode | Z program | Description | Standard app (Fiori / classic) | Business role |
|---|---|---|---|---|
| ZME49 | ZRM06EPS0 | Price comparison list | **Price Comparison** / `ME49`; **Compare Supplier Quotations** | `SAP_BR_PURCHASER` |
| ZMM60 | ZMAT_LIST | Material list | **Material List** / `MM60`; **Manage Material Master** (F1602) | `SAP_BR_BUYER` / `SAP_BR_MASTER_DATA_SPEC_MM` |

## Retirement procedure (per tcode)
1. **Confirm parity** — open the standard app and verify it covers the fields and
   selection the Z screen offered (most "Z…N" variants only re-skinned the
   standard transaction or added a layout).
2. **Migrate variants/layouts** — recreate saved selection variants and ALV
   layouts as standard app variants / display settings.
3. **Assign the role** — add the standard app's catalog to the listed
   `SAP_BR_*` business role (or your derived Z-role) in PFCG; publish the tile in
   the user's Space/Page.
4. **Reuse, don't rebuild** — line-item apps already expose the custom append
   fields (`ZZ…` on BSEG/BKPF, `ZVBAP`) as additional columns; surface them via
   key-user adaptation of the standard app rather than a custom report.
5. **Retire** — remove the Z transaction from menus/roles, mark the Z program
   obsolete, and drop the tile after a parallel-run period.

> Output-only pieces (print voucher `ZFB03`, credit/debit note `ZCRDRNOTE`) move
> their *form* to **Output Management** (see the `PRT` layer); the **data** comes
> from the standard app above.

## Net
17 `STD` tcodes → standard apps via business-role assignment. No development,
no custom tables, no tiles built here — pure clean-core reuse.
