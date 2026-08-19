# Label Master · RAP service — the one open field mapping

Backend note for [`apps/label-master`](../../apps/label-master), the clean-core
replacement for `ZLABEL` (`SAPMZ_PP_LABEL_001`).

Everything in that app is complete except the field names of the legacy table
`ZPP_LABEL`, which could not be read from KSD when it was written. This note is
the checklist to close that out — it takes about two minutes.

## Step 1 — read the table

`SE11` → Database table → `ZPP_LABEL` → *Fields*.

Write down the field names for these concepts (the aliases on the right are
fixed — they are what the whole app addresses):

| Concept | `ZPP_LABEL` field | Alias used by the app |
| --- | --- | --- |
| Plant | `_______` | `Plant` |
| Brand (Kejriwal / Karishma / Microtex / Blank) | `_______` | `Brand` |
| Line number within a brand | `_______` | `LabelNumber` |
| Material | `_______` | `Material` |
| Grade | `_______` | `Grade` |
| Shade | `_______` | `Shade` |
| Packing type | `_______` | `PackingType` |
| Label text | `_______` | `LabelText` |
| Active flag | `_______` | `IsActive` |
| Created on / by | `_______` / `_______` | `CreatedOn` / `CreatedBy` |
| Changed on / by | `_______` / `_______` | `ChangedOn` / `ChangedBy` |

The guesses currently in the code follow the naming of the sibling tables
`ZPP_PACK` and `ZPP_BATCHN`: `werks`, `brand`, `labelno`, `matnr`, `grade`,
`shade`, `ptype`, `labeltext`, `active`, `erdat`, `ernam`, `aedat`, `aenam`.

## Step 2 — patch two files

**`backend/src/zi_label_master.ddls.asddls`** — the `SELECT` list.

**`backend/src/zi_label_master.bdef.asbdef`** — the `mapping for zpp_label`
block. Every alias in the CDS must appear here, mapped to the same field.

Nothing else. `ZC_LABEL_MASTER`, `ZUI_LABEL_MASTER`, `ZUI_LABEL_MASTER_04`,
`ZBP_I_LABEL_MASTER` and the whole UI5 app address aliases only.

If a concept has no column on `ZPP_LABEL`, delete its line from **three**
places: the CDS select list, the BDEF mapping, and `zc_label_master.ddls.asddls`.

## Step 3 — the key

Confirm the real primary key. The app assumes `Plant + Brand + LabelNumber`,
which matches the legacy screen (plant in the group-box title, brand as the
radio group). If `ZPP_LABEL` also has `MANDT` only plus a single-field key,
adjust `key` in the CDS and drop `numbering : managed` from the BDEF — a
user-supplied key needs `field ( mandatory : create )` instead.

## Step 4 — numbering

`field ( readonly, numbering : managed ) LabelNumber;` makes RAP assign the
line number. That requires `LabelNumber` to be numeric or a `raw(16)` UUID.
If it is a character code the packing desk types by hand, replace that line
with:

```
field ( mandatory : create ) LabelNumber;
```

and drop `readonly`.

## Step 5 — activate

Activate `ZI_LABEL_MASTER` first (it will fail loudly on any wrong field name —
that is the point), then the projection, the behaviour definitions, the class,
the service definition, and finally publish the binding.

## Why managed, not unmanaged

Every other RAP object in `ZKGPL_FIORI` is `unmanaged`, because each one wraps a
standard BAPI (`BAPI_HU_UNPACK`, `BAPI_GOODSMVT_CREATE`,
`BAPI_PRODORDCONF_CANCEL`). The label master has no BAPI — it is a small custom
table that the packing desk edits directly. Managed RAP gives create, update,
delete, locking and ETag handling with no handler code at all, which is why the
behaviour pool `ZBP_I_LABEL_MASTER` is empty.
