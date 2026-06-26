# Min/Max Levels (ZMINMAX / ZSOL_MIN_MAX) — reuse STANDARD, do not build

> **Re-classified after the field-dictionary review.** This is **not** a genuine
> custom master. The program `ZSOL_MIN_MAX` maintains **min/max stock levels**,
> and the dictionary shows it touches only `ZZMARA` (a customer append on the
> material master) — there is **no dedicated Z-table** behind it. Min/Max stock
> is **standard material planning data**, so this is a clean-core **reuse**, not
> a rebuild.

## What it really is
"Maximum/Minimum" stock levels live on the standard material master MRP views:

| Field | Standard home |
|---|---|
| Reorder point (min) | `MARC-MINBE` (MRP 1) |
| Maximum stock level | `MARC-MABST` (MRP 1) |
| Safety stock | `MARC-EISBE` (MRP 2) |
| MRP type / lot size | `MARC-DISMM` / `MARC-DISLS` |

The textile-specific yarn attributes the old program also read (`ZZMARA`:
`ZZPDTYP`, `ZZDENIR`, `ZZFILAM`, `ZZLUSTER`, `ZZSHDCD`, …) are **already custom
fields on the material**, surfaced through key-user extensibility.

## Route — reuse existing infrastructure
1. **Maintain** min/max via the standard Fiori apps:
   - **Manage Material Master** / **Change Material (MM02)** MRP views, or
   - **Mass Maintenance of Materials** for bulk min/max updates.
2. If a focused "edit only min/max for a plant" screen is wanted, build it as a
   **key-user / adaptation** restricted view of the standard Manage Material app —
   **not** a new BO with a new table.
3. Expose the `ZZMARA` yarn attributes as **custom fields** on the standard
   material object (tier-1 key-user extensibility), reusing the append that
   already exists.

> No managed-RAP custom table is created for Min/Max. The previous skeleton (a
> fake `zminmax` table) has been removed because it would have duplicated
> standard MRP data.

## Branch
Tracked on `claude/fiori-app-extensions-h1nb64`.
