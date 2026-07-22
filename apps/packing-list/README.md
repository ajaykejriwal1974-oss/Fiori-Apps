# Packing List (ZPLIST01/02/03 + A/T/N/D variants) — custom Fiori app

Freestyle SAPUI5 worklist app, the clean-core replacement for the **14-transaction
ZPLIST family** (`ZPLIST01/02/03`, `ZPLISTD` and their `A` (IPL), `T` (HSM), `N`
variants — programs `ZSD_PACKING_LIST_01 / _IPL / _HSM / _N`). The plant/format
suffixes collapse into a single **Plant** dimension; Create / Change / Display /
Delete become one worklist with three actions.

Binds to the OData V4 service of [`backend/packing-list-rap`](../../backend/packing-list-rap)
(`PackingList` entity set).

## Worklist columns
`SalesOrder`, `SalesOrderItem`, `PackListItem`, `BoxNumber`, `Plant`, `Material`,
`Grade`, `NetWeight`, `Status`

## Actions
- `createPackingList` — Create (build a pack list from the selected boxes)
- `changePackingList` — Change (re-assign boxes / status)
- `deletePackingList` — Delete (soft delete: rows move to `ZPLISTD`)

> **Scaffold.** List binding and action buttons are wired; the backend
> `ZSOL_HUDISPATCH` insert/update and the `ZPLISTD` soft-delete are `TODO` in
> `zbp_i_packing_list.clas.locals_imp.abap` — mirror the legacy
> `ZSD_PACKING_LIST_01` logic (see VERIFY notes in the class).

## Placeholders to fill
- `REPLACE_WITH_SERVICE_NAMESPACE` (Worklist.controller.js) → the action namespace
  from the activated V4 service metadata.
- The `mainService` URI in `manifest.json` assumes binding name
  `ZUI_PACKING_LIST_04` — align with the binding created in ADT.

## Retires
`ZPLIST01, ZPLIST01A, ZPLIST01T, ZPLIST02, ZPLIST02A, ZPLIST02N, ZPLIST02T,
ZPLIST03, ZPLIST03A, ZPLIST03N, ZPLIST03T, ZPLISTD, ZPLISTDA, ZPLISTDT`
(print output `ZPLISTP` stays a classic print program by decision).

## Deploy
`npm install && npm run deploy` — BSP `ZPACKING_LIST`, package `ZKGPL_FIORI`.
Tile + target mapping: semantic object `PackingList`, action `manageKejriwal`
(keep tile and target-mapping casing identical — see the FLP audit of 22 Jul 2026).
