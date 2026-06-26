# ZBATCH_CHANGE – Contract Batch Update · Custom Fiori App

A **custom freestyle SAPUI5 app** for **mass batch assignment / update against a
sales contract**, the clean-core replacement for `ZBATCH_CHANGE`
(program `ZSOL_SALE_ORDER_BATCH_UPDATE`).

> Source of scope: `KEJRIWAL_Z_to_Fiori_Mapping.pdf`, Table B.

## ⚠️ Why this is NOT an adaptation project

Mass-updating batches across many contract items at once is a dedicated
interaction, not a field/section tweak on the standard Manage Sales Contracts
app. Per the mapping doc the clean-core option is a **custom RAP action over
contract + batch**, or mass-change via the standard API — this app provides the
UI for that.

> Related: the [Manage Sales Contracts adaptation project](../manage-sales-contracts-ext)
> covers the contract *status & rate* changes. This separate app covers the
> *mass batch* update.

## What it does

- **Load** a sales contract's items by contract number.
- **Mass-assign** a batch to all selected rows (`Apply to Selected`), or edit the
  `New Batch` per row.
- Tracks changed rows (`dirtyCount`) and **Update Batches** persists them in one
  round trip.

## Architecture

| Layer | This repo | To build |
|---|---|---|
| UI (freestyle UI5) | `webapp/` | — |
| OData V4 service | `manifest.json` (`mainService`) | **Custom RAP service**: read contract items + a mass-update action over (contract, item, batch) |
| FLP tile | inbound `SalesContract-updateBatchKejriwal` | Target mapping + tile (`docs/PUBLISHING.md`) |

### Backend (the critical dependency)

A **RAP/OData V4 service** exposing a contract-items entity
(`ContractItem`, `Material`, `MaterialDescription`, `CurrentBatch`, `NewBatch`)
and a **mass-update action** (or updatable `NewBatch` + batch submit). The
`onLoadContract` and `onUpdateBatches` `TODO`s in
`controller/Main.controller.js` mark where to wire it.

> A RAP **skeleton** for this service is authored at
> [`backend/contract-batch-rap`](../../backend/contract-batch-rap) (contract-items
> read + `updateBatches` static action → BAPI_SALESDOCUMENT_CHANGE). Point
> `REPLACE_WITH_CONTRACT_BATCH_SERVICE` at its binding `ZUI_CONTRACT_BATCH`.

## ⚠️ Placeholders you MUST replace

1. `REPLACE_WITH_CONTRACT_BATCH_SERVICE` (manifest `dataSources.mainService.uri`).
2. `REPLACE_WITH_ABAP_SYSTEM_URL` / client (`ui5.yaml`).
3. Entity/property names + the update payload must match the service.

## Run locally

```bash
npm install
npm start        # after replacing the REPLACE_WITH_* placeholders
```

## Publish

Deploys as a BSP (`npm run deploy`); own FLP tile via the
`SalesContract-updateBatchKejriwal` inbound. See
[`../../docs/PUBLISHING.md`](../../docs/PUBLISHING.md).

## Branch

Developed on `claude/fiori-app-extensions-h1nb64`.
