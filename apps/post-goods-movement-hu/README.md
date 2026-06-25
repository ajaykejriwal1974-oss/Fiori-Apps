# ZBOX_MOVE – Post Goods Movement (HU / Box) · Custom Fiori App

A **custom freestyle SAPUI5 app** for **box / handling-unit-wise goods
movement**, the clean-core replacement for `ZBOX_MOVE`
(program `ZSOL_POST_GOODS_MOVEMENTS`).

> Source of scope: `KEJRIWAL_Z_to_Fiori_Mapping.pdf`, Table B.

## ⚠️ Why this is NOT an adaptation project

`MIGO` is a GUI transaction (not a Fiori app), and box/HU-wise movement is a
distinct, scan-driven interaction. Per the mapping doc the clean-core option is
**Handling-Unit Management config + a thin custom Fiori app over the
goods-movement API** — this app — rather than adapting a standard app.

## What it does

- **Movement header**: movement type, plant, issuing & receiving storage location.
- **Scan panel**: scan/enter a **handling unit / box**; its contents are appended
  to the worklist (one round of HU read per scan).
- **Items table**: HU/box, material, description, batch, quantity, unit; remove
  rows individually or clear all.
- **Post Goods Movement**: creates one material document for all scanned items.

## Architecture

| Layer | This repo | To build |
|---|---|---|
| UI (freestyle UI5) | `webapp/` (Component, Main view+controller, i18n) | — |
| OData V4 service | declared in `manifest.json` (`mainService`) | **Custom RAP service** over the HU read + goods-movement APIs |
| FLP tile | inbound `MaterialDocument-postHuKejriwal` | Target mapping + tile (`docs/PUBLISHING.md`) |

### Backend service (the critical dependency)

Build a **RAP/OData V4 service** that:
1. Reads HU contents — a `HandlingUnitItem` entity (`HandlingUnit`, `Material`,
   `MaterialDescription`, `Batch`, `Quantity`, `Unit`), and
2. Posts the movement — a create/action mapping to the goods-movement API
   (classic equivalent: `BAPI_GOODSMVT_CREATE`) plus the standard HU update.

The two `TODO`s in `controller/Main.controller.js` (`onScanHu` read,
`onPostMovement` create) mark exactly where to wire these.

## ⚠️ Placeholders you MUST replace

1. `REPLACE_WITH_HU_GM_SERVICE` (manifest `dataSources.mainService.uri`).
2. `REPLACE_WITH_ABAP_SYSTEM_URL` / client (`ui5.yaml`).
3. Entity/property names in the controller TODOs must match the service.

## Run locally

```bash
npm install
npm start        # after replacing the REPLACE_WITH_* placeholders
```

## Publish

Deploys as a BSP (`npm run deploy`); own FLP tile via the
`MaterialDocument-postHuKejriwal` inbound. See
[`../../docs/PUBLISHING.md`](../../docs/PUBLISHING.md).

## Branch

Developed on `claude/fiori-app-extensions-h1nb64`.
