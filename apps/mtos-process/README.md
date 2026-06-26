# MTOS Process (ZMTOS, ZHUINV) — custom Fiori app

Freestyle SAPUI5 worklist app, the clean-core replacement for **ZSOL_MTOS_PROCESS (MTO->MTS transfer + phys. inv. doc)**.
Binds to the OData V4 service of [`backend/mtos-process-rap`](../../backend/mtos-process-rap)
(`MtosStock` entity set) and exposes the service's static action(s) as
table actions.

## Worklist columns
`Material`, `Plant`, `SalesOrder`, `SalesOrderItem`, `Quantity`, `BaseUnit`

## Actions
- `convertToMts` — Convert to MTS
- `createPhysInvDoc` — Create Phys. Inv. Document

> **Scaffold.** The list binding and action buttons are wired; the actual OData
> V4 action **invocation** is marked `TODO` in `webapp/controller/Worklist.controller.js`
> (build the parameter structure + `oOperation.invoke()`). The backend BAPIs are
> likewise `TODO` in the RAP behavior pool — see the backend README.

## Placeholders to fill
- `REPLACE_WITH_MTOS_PROCESS_SERVICE` (manifest.json) → the OData V4 service binding
  name created in ADT for service definition `ZUI_MTOS_PROCESS` (e.g. `ZUI_MTOS_PROCESS_O4`).
- `REPLACE_WITH_ABAP_SYSTEM_URL` (ui5.yaml) → the dev system URL (client 500).

## Reuse
Reuse existing `ZSOL_F4*` value-help views for material/plant/batch fields and
existing read CDS where available — see [`docs/REUSE-EXISTING.md`](../../docs/REUSE-EXISTING.md).

## Branch
Tracked on `claude/fiori-app-extensions-h1nb64`.
