# Inbound Delivery HUs (Route 7) - unmanaged RAP service (skeleton)

Custom transactional service for **Inbound Delivery HUs** (HUs in inbound delivery, replaces ZHUINB). Unmanaged RAP over
standard SAP (same family as the packing app / `backend/goods-movement-hu-rap`):
a read model + static action(s) calling standard BAPIs.

> **Skeleton.** Read source (`vekp`) + BAPI calls are best-effort -
> **VERIFY against your release and the original Z program** before activating.


## Actions
| Action | BAPI (to wire) | Purpose |
|---|---|---|
| `postInboundGr` | `BAPI_INB_DELIVERY_CONFIRM_DEC` | Post inbound GR for HUs |

## Objects in `src/`
Read CDS `ZI_InboundHu` / projection `ZC_InboundHu`, abstract import + result entities per
action, unmanaged behavior + projection behavior, behavior class `zbp_i_hu_inbound`
(BAPI TODO), service def `ZUI_HU_INBOUND`. Create the V4 binding `ZUI_HU_INBOUND_O4` in ADT.

## Branch
Developed on `claude/fiori-app-extensions-h1nb64`.
