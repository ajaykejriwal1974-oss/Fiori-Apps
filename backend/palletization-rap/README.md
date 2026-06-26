# Palletization (Route 7) - unmanaged RAP service (skeleton)

Custom transactional service for **Palletization** (boxes-on-pallet, replaces ZPALLET / ZPALLET1 / ZPAL_BOX / ZSOL_ASRS). Built as **unmanaged
RAP** over standard SAP (same pattern as `backend/goods-movement-hu-rap`): a read
model + static action(s) that call standard BAPIs.

> **Skeleton.** The read source (`vekp`) and BAPI calls are best-effort -
> **VERIFY against your release and the original Z program** before activating.

> Closely related to the [dyeing-packing](../../apps/dyeing-packing) app / `backend/packing-hu-rap`; consolidate if you prefer one packing app.

## Actions
| Action | BAPI (to wire) | Purpose |
|---|---|---|
| `packPallet` | `BAPI_HU_PACK` | Pack boxes onto a pallet |

## Objects in `src/`
Read CDS `ZI_Pallet` / projection `ZC_Pallet`, abstract import + result entities per
action, unmanaged behavior + projection behavior, behavior class `zbp_i_palletization`
(BAPI TODO in the handler), service def `ZUI_PALLETIZATION`.
Create the **OData V4 service binding `ZUI_PALLETIZATION_O4`** in ADT.

## Branch
Developed on `claude/fiori-app-extensions-h1nb64`.
