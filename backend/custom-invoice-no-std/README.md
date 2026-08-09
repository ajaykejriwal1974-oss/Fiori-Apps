# Custom Invoice Number (ZEXN) — reuse STANDARD, do not build

> **Re-classified (Phase 1 review).** `ZEXN` ("Maintain Custom Invoice Number") has
> **no program and no Z-table** in the dictionary (classification source = "—").
> There is nothing custom behind it — it is a **numbering/config** need met by
> standard SAP. Clean-core **reuse**, not a rebuild.

## What it really is
A dedicated number for (customs/export) invoices. In S/4HANA this is standard:

| Need | Standard mechanism |
|---|---|
| Billing document number range | `VN01` / number range object `RV_BELEG`, assigned per billing type in `VOFA` |
| Official Document Numbering (India ODN) for outgoing invoices | Standard ODN config (FI `J_1IG*` / SD official doc numbering), no custom table |
| Export/customs invoice reference | Standard billing header reference fields + output |

## Route — reuse standard
1. Maintain the billing-type number range in standard config (`VOFA` → number range).
2. If a statutory ODN sequence is required, configure standard Official Document
   Numbering — do **not** persist invoice numbers in a custom table.
3. Surface via the standard **Manage Billing Documents** / **Create Billing
   Documents** Fiori apps.

> No custom RAP object or table is created for `ZEXN`. Routing stub only (no `src/`).
> VERIFY on KSD: confirm whether `ZEXN` was customs-invoice numbering vs export ODN,
> then point it at the matching standard config. See [`docs/PHASE1_ROUTE_TO_STANDARD.md`](../../docs/PHASE1_ROUTE_TO_STANDARD.md).
