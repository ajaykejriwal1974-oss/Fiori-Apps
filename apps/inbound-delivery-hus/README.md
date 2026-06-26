# Inbound Delivery HUs (ZHUINB) — custom Fiori app

Freestyle SAPUI5 worklist app, the clean-core replacement for **ZSOL_INBOUND_HU**.
Binds to the OData V4 service of [`backend/hu-inbound-rap`](../../backend/hu-inbound-rap)
(`InboundHu` entity set) and exposes the service's static action(s) as
table actions.

## Worklist columns
`HandlingUnit`, `InboundDelivery`, `PackagingMaterial`

## Actions
- `postInboundGr` — Post Inbound GR

> **Scaffold.** The list binding and action buttons are wired; the actual OData
> V4 action **invocation** is marked `TODO` in `webapp/controller/Worklist.controller.js`
> (build the parameter structure + `oOperation.invoke()`). The backend BAPIs are
> likewise `TODO` in the RAP behavior pool — see the backend README.

## Placeholders to fill
- `REPLACE_WITH_HU_INBOUND_SERVICE` (manifest.json) → the OData V4 service binding
  name created in ADT for service definition `ZUI_HU_INBOUND` (e.g. `ZUI_HU_INBOUND_O4`).
- `REPLACE_WITH_ABAP_SYSTEM_URL` (ui5.yaml) → the dev system URL (client 500).

## Reuse
Reuse existing `ZSOL_F4*` value-help views for material/plant/batch fields and
existing read CDS where available — see [`docs/REUSE-EXISTING.md`](../../docs/REUSE-EXISTING.md).

## Branch
Tracked on `claude/fiori-app-extensions-h1nb64`.
