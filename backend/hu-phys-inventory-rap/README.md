# HU Physical Inventory (Route 7) - unmanaged RAP service (skeleton)

Custom transactional service for **HU Physical Inventory** (HU physical inventory, replaces ZHUINV). Unmanaged RAP over
standard SAP (same family as the packing app / `backend/goods-movement-hu-rap`):
a read model + static action(s) calling standard BAPIs.

> **Skeleton.** Read source (`vekp`) + BAPI calls are best-effort -
> **VERIFY against your release and the original Z program** before activating.

> Assess standard **Physical Inventory** first; build only if HU-wise creation isn't covered.

## Actions
| Action | BAPI (to wire) | Purpose |
|---|---|---|
| `createPhysInvDoc` | `BAPI_MATPHYSINV_CREATE_MULT` | Create phys. inventory doc for HUs |

## Objects in `src/`
Read CDS `ZI_HuPhysInv` / projection `ZC_HuPhysInv`, abstract import + result entities per
action, unmanaged behavior + projection behavior, behavior class `zbp_i_hu_phys_inventory`
(BAPI TODO), service def `ZUI_HU_PHYS_INV`. Create the V4 binding `ZUI_HU_PHYS_INV_O4` in ADT.

## Branch
Developed on `claude/fiori-app-extensions-h1nb64`.
