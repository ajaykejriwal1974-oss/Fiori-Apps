# Packing Details (Route 7) - unmanaged RAP service (skeleton)

Custom transactional service for **Packing Details** (general packing + repack, replaces ZPACK01/02/03(+N) and ZREPACK). Unmanaged RAP over
standard SAP (same family as the packing app / `backend/goods-movement-hu-rap`):
a read model + static action(s) calling standard BAPIs.

> **Skeleton.** Read source (`vepo as item
    inner join vekp as hu on hu.venum = item.venum`) + BAPI calls are best-effort -
> **VERIFY against your release and the original Z program** before activating.

> Sibling of the dyeing-specific [dyeing-packing](../../apps/dyeing-packing) app / `backend/packing-hu-rap`.

## Actions
| Action | BAPI (to wire) | Purpose |
|---|---|---|
| `packItems` | `BAPI_HU_PACK` | Pack items into a new HU |
| `repackItems` | `BAPI_HU_REPACK_ITM` | Repack items between HUs (ZREPACK) |

## Objects in `src/`
Read CDS `ZI_PackingItem` / projection `ZC_PackingItem`, abstract import + result entities per
action, unmanaged behavior + projection behavior, behavior class `zbp_i_packing_detail`
(BAPI TODO), service def `ZUI_PACKING_DETAIL`. Create the V4 binding `ZUI_PACKING_DETAIL_O4` in ADT.

## Branch
Developed on `claude/fiori-app-extensions-h1nb64`.
