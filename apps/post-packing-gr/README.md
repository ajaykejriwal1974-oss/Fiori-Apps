# Post Packing & GR (ZPOST01) — custom Fiori app

Freestyle SAPUI5 worklist app, the clean-core replacement for **ZPP_PACK_POST**.
Binds to the OData V4 service of [`backend/post-packing-gr-rap`](../../backend/post-packing-gr-rap)
(`PostPackGr` entity set) and exposes the service's static action(s) as
table actions.

## Worklist columns
`HandlingUnit`, `PackagingMaterial`, `Reference`

## Actions
- `postPackingAndGr` — Post Packing & GR

> **Scaffold.** The list binding and action buttons are wired; the actual OData
> V4 action **invocation** is marked `TODO` in `webapp/controller/Worklist.controller.js`
> (build the parameter structure + `oOperation.invoke()`). The backend BAPIs are
> likewise `TODO` in the RAP behavior pool — see the backend README.

## Placeholders to fill
- `REPLACE_WITH_POST_PACK_GR_SERVICE` (manifest.json) → the OData V4 service binding
  name created in ADT for service definition `ZUI_POST_PACK_GR` (e.g. `ZUI_POST_PACK_GR_O4`).
- `REPLACE_WITH_ABAP_SYSTEM_URL` (ui5.yaml) → the dev system URL (client 500).

## Reuse
Reuse existing `ZSOL_F4*` value-help views for material/plant/batch fields and
existing read CDS where available — see [`docs/REUSE-EXISTING.md`](../../docs/REUSE-EXISTING.md).

## Branch
Tracked on `claude/fiori-app-extensions-h1nb64`.
