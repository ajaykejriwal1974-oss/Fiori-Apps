# Bill of Exchange (ZBOE) — reuse STANDARD, do not build

> **Re-classified after review.** `ZBOE` is classified `CUS` in the portfolio,
> but it has **no program and no Z-tables** in the dictionary — there is nothing
> custom behind it. Bill of Exchange is **standard SAP Financials**, so this is a
> clean-core **reuse**, not a rebuild.

## What it really is
Bill of Exchange (B/E, "hundi" in India) is standard FI functionality — a special
G/L transaction on the customer/vendor sub-ledger. It is delivered as classic
transactions (still fully supported in S/4HANA 2025):

| Process | Standard transaction |
|---|---|
| B/E receivable — payment / receipt | `F-36` (bill of exchange payment), `FBW1` |
| B/E discounting / usage | `F-33` (discounting), `FBW2` / `FBW3` |
| B/E presentation & reverse contingent liability | `FBW4` / `FBW6` |
| B/E charges / forfaiting | `F-34`, `FBWD` |
| Customer / vendor down-payment & special G/L | `F-29` / `F-48` family |

Bills of exchange post against special G/L indicators (`W` for B/E receivable),
configured in **Financial Accounting → Bank Accounting → Business Transactions →
Bill of Exchange Transactions** — not in any custom table.

## Route — reuse standard
1. **Configure** the special G/L indicators and B/E G/L accounts in standard FI
   customizing (likely already present if `ZBOE` was in use).
2. **Process** B/E via the standard transactions above; surface them in the FLP
   as transaction tiles, or via the standard **Manage Customer / Supplier Line
   Items** Fiori apps (special G/L line items) and **Post General Journal Entries**.
3. **Report** open bills of exchange through the standard AR/AP line-item and
   aging apps — no custom report needed.

> No custom RAP object or table is created for `ZBOE`. This folder is a routing
> stub only (no `src/`). See [`docs/CLASSIFICATION.md`](../../docs/CLASSIFICATION.md)
> and [`docs/REUSE-EXISTING.md`](../../docs/REUSE-EXISTING.md).

## Branch
Tracked on `claude/fiori-app-extensions-h1nb64`.
