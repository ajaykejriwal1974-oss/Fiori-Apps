# WIP Batch Close

Close and reopen dyeing WIP batches. Clean-core replacement for the GUI report
**`zbatch_cls`** — *"WIP Batch close for plant 2002"*.

Closes gap #2 from `docs/fiori-gap-analysis-2026-08-19.md`. The plant's own note
on the scanned runbook page reads simply: **"Needed"**.

## Why it matters

The runbook explains the dependency in one line:

> Two job cards in production. After clearing production in `zbatch_cls`,
> to cancel or deduct, **the Batch Master must be open**.

So closing and reopening a WIP batch is not housekeeping — it gates the
*Cancel Production Confirmation* app. A confirmation cannot be reversed while
its batch is closed. The two apps are used together.

The existing **WIP Batch** tile (`ZC_WIP_BATCH`, analytical) *shows* the
`Closed` flag but cannot change it. This app is the transactional twin.

## What it does

- Filter-first worklist over `ZPP_BATCHN`: company code, plant, batch,
  production order, batch-date range, grey/dyed material, and an
  **All / Open / Closed** status selector.
- Multi-select → **Close** or **Reopen**.
- **Close** skips rows already closed; confirmation prompt; no reason needed.
- **Reopen** is treated as the destructive direction — it requires a free-text
  reason, enforced both in the dialog and in the handler.
- Quick search, sort, Excel export.

## Backend objects (`backend/src`, package `ZKGPL_FIORI`)

| Object | Type | Purpose |
| --- | --- | --- |
| `ZI_WIP_BATCH_MGMT` | DDLS | Root view over `ZPP_BATCHN` + `T001K` (company code via valuation area) |
| `ZC_WIP_BATCH_MGMT` | DDLS | Projection, `provider contract transactional_query` |
| `ZD_WIP_BATCH_CLOSE` | DDLS | Abstract entity — action import (`Reason`, `BatchList`) |
| `ZD_WIP_BATCH_RESULT` | DDLS | Abstract entity — action result |
| `ZI_WIP_BATCH_MGMT` | BDEF | Unmanaged; `closeBatches`, `reopenBatches` |
| `ZC_WIP_BATCH_MGMT` | BDEF | Projection |
| `ZBP_I_WIP_BATCH_MGMT` | CLAS | Behaviour pool — updates `ZPP_BATCHN-CLOSED` |
| `ZUI_WIP_BATCH_MGMT` | SRVD | Service definition (+ 3 value-help entity sets) |
| `ZUI_WIP_BATCH_04` | SRVB | OData V4 binding |

Service URI: `/sap/opu/odata4/sap/zui_wip_batch_04/srvd/sap/zui_wip_batch_mgmt/0001/`

### Naming note

`ZD_BATCH_CLOSE` / `ZD_BATCH_CLOSE_RESULT` already exist in `ZKGPL_FIORI` and
belong to **`ZI_BATCH_STATUS`**, which closes the *material batch master*
(`MCHA`). That is a different object from the dyeing WIP batch (`ZPP_BATCHN`).
This app therefore uses `ZD_WIP_BATCH_CLOSE` / `ZD_WIP_BATCH_RESULT`. Do not
merge the two — they have different keys and different semantics.

### Action contract

```
closeBatches / reopenBatches
  Reason    : abap.char(80)      " mandatory for reopen, ignored for close
  BatchList : abap.char(1333)    " 'BATCH=YEAR;BATCH=YEAR;...'
```

Same flat-string pattern as `ZI_HU_UNPACK` and `ZI_PROD_CONFIRMATION`.

The handler guards each row before writing: batch must exist, and must not
already be in the target state. The `COMMIT WORK AND WAIT` fires once, only if
at least one row actually changed.

## Deploy

1. abapGit pull in `ZABAPGIT` on KSD, then activate in Eclipse (ADT).
2. Publish service binding `ZUI_WIP_BATCH_04`.
3. Confirm `SERVICE_NS` in `webapp/controller/Worklist.controller.js` matches
   `/$metadata` (expected `com.sap.gateway.srvd.zui_wip_batch_mgmt.v0001`).
4. `npm install && npm run deploy` — BSP application `ZWIP_BATCH_CLS`.
5. Add the tile to the **Production** space; semantic object `WipBatch`,
   action `closeKejriwal`. Put it next to **WIP Batch** and **Confirm
   Production Operation**.

## Authorisations

The handler writes `ZPP_BATCHN` directly, exactly as `zbatch_cls` does. Restrict
the tile to the production supervisors who hold `zbatch_cls` today — reopening a
batch is what unlocks confirmation reversal, so it should not be given to every
operator.
