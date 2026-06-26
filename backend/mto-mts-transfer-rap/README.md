# MTO to MTS Transfer (Route 7) - unmanaged RAP service (skeleton)

Custom transactional service for **MTO to MTS Transfer** (transfer MTO to MTS stock, replaces ZMTOS). Built as **unmanaged
RAP** over standard SAP (same pattern as `backend/goods-movement-hu-rap`): a read
model + static action(s) that call standard BAPIs.

> **Skeleton.** The read source (`mska`) and BAPI calls are best-effort -
> **VERIFY against your release and the original Z program** before activating.


## Actions
| Action | BAPI (to wire) | Purpose |
|---|---|---|
| `convertToMts` | `BAPI_GOODSMVT_CREATE` | Convert MTO stock to MTS |

## Objects in `src/`
Read CDS `ZI_MtoStock` / projection `ZC_MtoStock`, abstract import + result entities per
action, unmanaged behavior + projection behavior, behavior class `zbp_i_mto_mts_transfer`
(BAPI TODO in the handler), service def `ZUI_MTO_MTS`.
Create the **OData V4 service binding `ZUI_MTO_MTS_O4`** in ADT.

## Branch
Developed on `claude/fiori-app-extensions-h1nb64`.
