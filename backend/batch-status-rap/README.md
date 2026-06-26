# Batch Status (Route 7) - unmanaged RAP service (skeleton)

Custom transactional service for **Batch Status** (batch close / delete, replaces ZBATCH_CLS / ZBATCHD). Built as **unmanaged
RAP** over standard SAP (same pattern as `backend/goods-movement-hu-rap`): a read
model + static action(s) that call standard BAPIs.

> **Skeleton.** The read source (`mcha`) and BAPI calls are best-effort -
> **VERIFY against your release and the original Z program** before activating.

> Could also be actions on standard Manage Batches (F2462) instead of a separate service.

## Actions — wired ✅
| Action | Implementation | Purpose |
|---|---|---|
| `closeBatch` | UPDATE custom WIP table `ZPP_BATCHN` (CLOSED + who/when) | Close a WIP batch (replaces `ZSOL_WIP_BATCH_CLOSE`) |
| `deleteBatch` | `BAPI_BATCH_CHANGE` (deletion flag) | Flag a batch for deletion |

> VERIFY: the `ZPP_BATCHN` key (BATCHNO [+ GJAHR]) and `BAPI_BATCH_CHANGE`
> MATERIAL vs MATERIAL_LONG for your release.

## Objects in `src/`
Read CDS `ZI_BatchStatus` / projection `ZC_BatchStatus`, abstract import + result entities per
action, unmanaged behavior + projection behavior, behavior class `zbp_i_batch_status`
(BAPI TODO in the handler), service def `ZUI_BATCH_STATUS`.
Create the **OData V4 service binding `ZUI_BATCH_STATUS_O4`** in ADT.

## Branch
Developed on `claude/fiori-app-extensions-h1nb64`.
