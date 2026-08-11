# Plant Dashboard (Fiori)

KPI landing page across **all companies** with one-tap drill-into the operational apps.

## What it shows
Live `$count` KPIs grouped by area, each tile navigates (cross-app) to its app:

| KPI | Service (entity) | Drill-into |
|---|---|---|
| Open Batches | zui_batch_status (Batch) | BatchStatus-manageKejriwal |
| Packing Items | zui_packing_detail (PackingItem) | PackingDetail-manageKejriwal |
| Pallets | zui_palletization (Pallet) | Palletization-manageKejriwal |
| Pending Contracts | zui_contract_batch (SalesContract*) | SalesContract-updateBatchKejriwal |
| Dispatch Backlog | zui_dispatch_correction (DispatchBox) | DispatchCorrection-manageKejriwal |
| Low-Stock Alerts | zui_mtos_process (MtosStock, Quantity<100*) | MtosProcess-manageKejriwal |
| HUs to Unpack | zui_hu_unpack (HuUnpack) | HuUnpack-manageKejriwal |
| Inbound HUs | zui_hu_inbound (InboundHu) | InboundDeliveryHu-manageKejriwal |
| Inspections | zui_qm_inspectionchar (InspectionCharacteristic) | InspectionResult-recordMassKejriwal |

Each service is queried independently; an unreachable service degrades to **"-"** (never crashes).

## To verify / refine (`controller/Dashboard.controller.js` -> `KPIS`)
- `*` **Pending Contracts** entity set `/SalesContract` is a best guess — confirm the real entity of `zui_contract_batch` and adjust `path`.
- `*` **Low-Stock** threshold `Quantity < 100` is a placeholder — set your real reorder level.
- Add status filters where an "open/pending" field exists (e.g. DispatchBox status) to make counts semantic rather than totals.

## Deploy
Same as the other apps: `fiori deploy` (BSP `ZPLANT_DASHBOARD`, package `$TMP`), then a tile/target-mapping for `PlantDashboard-display`, and add it to the launchpad.

> Tiles render once SAPUI5 >= 1.136.10 is applied (see the getSite/CDM patch note) - same framework dependency as the spaces.
