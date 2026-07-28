# Phase 3 — Analytics (scope & reconciliation)

23 Jul 2026. Phase 3 = the surviving custom BI reports built as CDS analytical
queries (read-only cube+query pairs in [`backend/analytics`](../backend/analytics)).
11 were already built earlier (packed stock, packing register, WIP, HU inventory,
pending contract, export register, merge, recipe, job card, dispatch, GST) plus the
Phase-1 Credit/Debit query. This phase adds the remaining registers and routes the
FI ones to standard.

## Built this phase (4 new queries)
| Query | Cube source | Replaces |
|---|---|---|
| `ZC_SALES_REGISTER` | `VBRK` + `VBRP` (billing) | ZSALES, ZSALESN, ZSALESB, ZSOREG (sales report / order register / branch — now dimensions) |
| `ZC_TDS` | `WITH_ITEM` (withholding line items) | ZFI_TDS, ZQTDS (vendor/customer/quarterly — now dimensions/period) |
| `ZC_AUDIT_LOG` | `ZEINV_AUDITLOG` | ZAUDIT_LOG (e-invoice/e-way IRN status register) |
| `ZC_JOBWORK_CHALLAN` | `ZCTA_MM_JOB` + `MSEG` | ZJWCHLN (job-work challan) |

Consume in the **Query Browser** / an **Analytical List Page** / external BI — no
service binding, publish, or tile needed (read-only queries).

## Routed to STANDARD (no build)
| Z-report | Standard |
|---|---|
| `ZFI005`, `ZFICAG` (customer/debtors ageing) | **Customer Balances / Overdue Receivables**, **Aging Analysis** standard apps (`SAP_BR_AR_ACCOUNTANT`) |
| `ZFI007` (vendor ageing) | **Supplier Balances / Overdue Payables** (`SAP_BR_AP_ACCOUNTANT`) |
| `ZFICSR`, `ZFIGSR`, `ZFIVSR` (account statements) | Standard **Customer / G-L / Supplier Account Statement** apps |
| `ZMB5B`, `ZCMM001`, `ZBSTOCK` (generic stock) | **MB5B**, **Material Documents Overview**, standard batch stock (already decided, audit §H) |

## Flagged — NOT a pure analytical query
| Z-report | Why |
|---|---|
| `ZFINT` / `ZFINT1` (Interest Report) | Interest = rate × days-overdue × balance — a *calculation*, not an aggregation. An analytical CDS query can't compute it; keep as an ABAP report, or use standard **Interest Calculation** (FINT/`SAP_BR_AR_ACCOUNTANT`). Decide with FI. |
| `ZCSD001` (unassign return boxes) | This is an **action** (clears box assignment), not a report — small RAP action or route, not a query. |
| `ZCOMM` (commission) | Kept as its own report/query (audit said keep 1); build only if the commission logic is straightforward. |

## Deploy
Staged in `backend/_abapgit_import/src`. abapGit **Pull** into ZKGPL_FIORI →
activate (2nd pass if any inactive on first). No binding/publish. VERIFY notes:
- `ZC_TDS`: vendor/customer (LIFNR/KUNNR) is on the FI line BSEG — join if the
  register must show the partner.
- `ZC_JOBWORK_CHALLAN`: MSEG join is on MBLNR only (ZCTA_MM_JOB has no doc year).
