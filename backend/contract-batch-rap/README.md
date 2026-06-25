# Contract Batch Update · RAP Service (skeleton)

Backend **OData V4 service** for the
[Contract Batch Update](../../apps/contract-batch-update) app (replaces
`ZBATCH_CHANGE`). Reads a contract's items and mass-updates their batch.

> **Skeleton, not compile-ready.** Verify the `vbak`/`vbap` fields, the contract
> document-category filter, and the sales-document change API in ADT. Prefer the
> released `I_SalesContract*` CDS interfaces where your release offers them.

## Design

Unmanaged RAP - the batch change is a standard sales-document change BAPI.

| File | Object | Role |
|---|---|---|
| `zi_contract_item.ddls.asddls` | CDS `ZI_Contract_Item` | Contract items over `vbak`/`vbap` (load read) |
| `zc_contract_item.ddls.asddls` | CDS `ZC_Contract_Item` | Projection (`transactional_query`) |
| `zd_ctr_batch_update.ddls.asddls` | Abstract entity | Action import header (contract) + `_Item` |
| `zd_ctr_batch_item.ddls.asddls` | Abstract entity | Action import item (contract item, new batch) |
| `zd_ctr_batch_result.ddls.asddls` | Abstract entity | Action result (items updated, message) |
| `zi_contract_item.bdef.asbdef` | Behavior (unmanaged) | static action `updateBatches` |
| `zc_contract_item.bdef.asbdef` | Projection behavior | `use action updateBatches` |
| `zbp_i_contract_item.clas.*` | Behavior pool + handler | changes batches via `BAPI_SALESDOCUMENT_CHANGE` |
| `zui_contract_batch.srvd.srvdsrv` | Service def `ZUI_CONTRACT_BATCH` | exposes `ZC_Contract_Item` as `ContractItem` |

Create in ADT: **service binding `ZUI_CONTRACT_BATCH_O4`** (OData V4 – UI).

## Complete (TODO / VERIFY)

1. Read CDS: confirm `vbak`/`vbap` fields + the contract `vbtyp` filter.
2. Handler: change the batch per item via `BAPI_SALESDOCUMENT_CHANGE`
   (or the contract-specific change BAPI); messages → reported/failed;
   commit on success.
3. Authorization (sales-org / contract).

## Wiring to the app

- App `manifest.json` → `REPLACE_WITH_CONTRACT_BATCH_SERVICE` = `ZUI_CONTRACT_BATCH`;
  entity set `ContractItem` matches the load read.
- App `controller/Main.controller.js`:
  - `onLoadContract` → read `ContractItem` filtered by `SalesContract`.
  - `onUpdateBatches` → call the `updateBatches` action with the changed rows
    (`{ContractItem, NewBatch}`) - matches the app's `_changedItems()`.

## Branch
Developed on `claude/fiori-app-extensions-h1nb64`.
