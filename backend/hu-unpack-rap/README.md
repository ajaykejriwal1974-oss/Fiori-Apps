# HU Unpack (Route 7) - unmanaged RAP service (skeleton)

Custom transactional service for **HU Unpack** (RM unpack, replaces ZHUPK). Built as **unmanaged
RAP** over standard SAP (same pattern as `backend/goods-movement-hu-rap`): a read
model + static action(s) that call standard BAPIs.

> **Skeleton.** The read source (`vepo as item
    inner join vekp as hu on hu.venum = item.venum`) and BAPI calls are best-effort -
> **VERIFY against your release and the original Z program** before activating.

> Overlaps the [post-goods-movement-hu](../../apps/post-goods-movement-hu) app - reuse its UI if a separate tile isn't needed.

## Actions
| Action | BAPI (to wire) | Purpose |
|---|---|---|
| `unpackItems` | `BAPI_HU_UNPACK` | Unpack items from handling units |

## Objects in `src/`
Read CDS `ZI_HuUnpackItem` / projection `ZC_HuUnpackItem`, abstract import + result entities per
action, unmanaged behavior + projection behavior, behavior class `zbp_i_hu_unpack`
(BAPI TODO in the handler), service def `ZUI_HU_UNPACK`.
Create the **OData V4 service binding `ZUI_HU_UNPACK_O4`** in ADT.

## Branch
Developed on `claude/fiori-app-extensions-h1nb64`.
