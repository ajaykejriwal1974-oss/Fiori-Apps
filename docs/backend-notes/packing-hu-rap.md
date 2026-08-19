# Dyeing Packing · RAP Service (skeleton)

Backend **OData V4 service** for the
[Dyeing Packing](../../apps/dyeing-packing) app (replaces `ZPACK01D/02D/03D`,
`ZREPACKD`). Reads existing handling units for a reference and creates the
textile cone → carton → pallet HU hierarchy.

> **Skeleton, not compile-ready.** Verify the `vekp` fields + reference link and
> the standard HU API mapping in ADT. **First check whether standard HU
> Management + packing instructions can model your structure** - prefer config
> over this service if so.

## Design

Unmanaged RAP - packing is created through the standard HU API, no custom table.

| File | Object | Role |
|---|---|---|
| `zi_packing_unit.ddls.asddls` | CDS `ZI_Packing_Unit` | Existing HUs for a reference (Repack read) |
| `zc_packing_unit.ddls.asddls` | CDS `ZC_Packing_Unit` | Projection (`transactional_query`) |
| `zd_pack_create.ddls.asddls` | Abstract entity | Action import header (reference, material, batch, shade) + `_Unit` |
| `zd_pack_create_unit.ddls.asddls` | Abstract entity | Action import unit (level, packing material, qty, net/gross weight) |
| `zd_pack_result.ddls.asddls` | Abstract entity | Action result (HUs created, top HU, message) |
| `zi_packing_unit.bdef.asbdef` | Behavior (unmanaged) | static action `createHandlingUnits` |
| `zc_packing_unit.bdef.asbdef` | Projection behavior | `use action createHandlingUnits` |
| `zbp_i_packing_unit.clas.*` | Behavior pool + handler | builds the HU hierarchy via `BAPI_HU_CREATE` / `BAPI_HU_PACK` |
| `zui_packing.srvd.srvdsrv` | Service def `ZUI_PACKING` | exposes `ZC_Packing_Unit` as `PackingUnit` |

Create in ADT: **service binding `ZUI_PACKING_O4`** (OData V4 – UI).

## Complete (TODO / VERIFY)

1. Read CDS: confirm `vekp` fields + the reference link (`vpobj`/`vpobjkey`).
2. Handler: create + pack each level (Cone→Carton→Pallet) via the HU API,
   carrying net/gross weights and linking to the reference; messages →
   reported/failed; commit on success.
3. Authorization (plant / packing).

## Wiring to the app

- App `manifest.json` → `REPLACE_WITH_PACKING_SERVICE` = `ZUI_PACKING`.
- App `controller/Main.controller.js`:
  - `onCreateHus` → call `createHandlingUnits` with the header + the `/units`
    table (level, packing material, qty, net/gross weight).
  - `onRepack` → read `PackingUnit` filtered by `Reference` and repopulate.

## Branch
Developed on `claude/fiori-app-extensions-h1nb64`.
