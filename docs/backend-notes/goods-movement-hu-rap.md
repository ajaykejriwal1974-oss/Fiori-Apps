# HU Goods Movement · RAP Service (skeleton)

Backend **OData V4 service** for the
[Post Goods Movement (HU / Box)](../../apps/post-goods-movement-hu) app
(replaces `ZBOX_MOVE`). Reads handling-unit contents and posts one material
document for all scanned items.

> **Skeleton, not compile-ready.** HU table/field names and the
> `BAPI_GOODSMVT_CREATE` mapping must be **verified against your release** in ADT.
> Structure and RAP wiring are complete; specifics are marked `TODO` / `VERIFY`.

## Design

Unmanaged RAP - there is no custom persistence; the post is a BAPI call.

| File | Object | Role |
|---|---|---|
| `zi_hu_item.ddls.asddls` | CDS `ZI_HU_Item` | HU items over `vekp`/`vepo` (scan read) |
| `zc_hu_item.ddls.asddls` | CDS `ZC_HU_Item` | Projection (`transactional_query`) |
| `zd_hu_post_movement.ddls.asddls` | Abstract entity | Action import header (movement type, plant, storage locs) + `_Item` composition |
| `zd_hu_post_mvt_item.ddls.asddls` | Abstract entity | Action import item (HU, material, batch, qty, unit) |
| `zd_hu_mvt_result.ddls.asddls` | Abstract entity | Action result (material document + message) |
| `zi_hu_item.bdef.asbdef` | Behavior (unmanaged) | static action `postGoodsMovement` |
| `zc_hu_item.bdef.asbdef` | Projection behavior | `use action postGoodsMovement` |
| `zbp_i_hu_item.clas.*` | Behavior pool + handler | builds `BAPI_GOODSMVT_CREATE`, returns the doc number |
| `zui_hu_goods_movement.srvd.srvdsrv` | Service def `ZUI_HU_GOODS_MOVEMENT` | exposes `ZC_HU_Item` as `HandlingUnitItem` |

Create in ADT: **service binding `ZUI_HU_GOODS_MOVEMENT_O4`** (OData V4 – UI).

## Status — BAPI wired ✅

`postGoodsMovement` now calls **`BAPI_GOODSMVT_CREATE`** for real: builds the GM
header + items from the action parameters, evaluates `return`, rolls back on
error and `BAPI_TRANSACTION_COMMIT`s on success, returning the material document.

Remaining **VERIFY** on the system:
1. Read CDS: confirm `vekp`/`vepo` fields for your release (shared via `hu-shared`).
2. `gm_code` is set to `'04'` (transfer posting / MB1B) — change to `'03'` (issue)
   or `'01'` (receipt) per the box/HU movement type your flow uses.
3. Add authorization (plant / movement-type checks).

## Wiring to the app

- App `manifest.json` → `REPLACE_WITH_HU_GM_SERVICE` = `ZUI_HU_GOODS_MOVEMENT`;
  entity set `HandlingUnitItem` matches the scan-read.
- App `controller/Main.controller.js`:
  - `onScanHu` → read `HandlingUnitItem` filtered by `HandlingUnit`.
  - `onPostMovement` → call the `postGoodsMovement` action with the header +
    items payload (replaces the current `TODO` MessageToast).

## Branch
Developed on `claude/fiori-app-extensions-h1nb64`.
