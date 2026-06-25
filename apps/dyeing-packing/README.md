# ZPACK / ZREPACKD – Dyeing Packing · Custom Fiori App

A **custom freestyle SAPUI5 app** for the **textile dyeing packing structure**
(cone → carton → pallet, with net/gross weights), the clean-core replacement for
`ZPACK01D / ZPACK02D / ZPACK03D` and `ZREPACKD`
(program `ZPP_PACK_MODULE_DYING`).

> Source of scope: `KEJRIWAL_Z_to_Fiori_Mapping.pdf`, Table B.

## ⚠️ Why this is NOT an adaptation project

The textile packing structure (cone/carton/pallet with weights and the dyeing
module) is a bespoke interaction. Per the mapping doc the clean-core option is
**Handling-Unit Management + packing instructions**, and **a custom Fiori packing
app (RAP) if HU config can't model it** — this app.

> First check whether **standard HU Management + packing instructions** can model
> your cone/carton/pallet structure. If it can, prefer config over this app. Use
> this app when the textile structure can't be expressed in standard HU config.

## What it does

- **Packing header**: order/delivery reference, material, batch, shade.
- **Add Cone / Carton / Pallet** rows to build the packing structure.
- **Per-row**: packing material, quantity, net & gross weight; live **net/gross
  totals**; remove rows; **Repack** to rebuild.
- **Create Handling Units**: builds the HU hierarchy for the reference.

## Architecture

| Layer | This repo | To build |
|---|---|---|
| UI (freestyle UI5, `sap.ui.table`) | `webapp/` | — |
| OData V4 service | `manifest.json` (`mainService`) | **Custom RAP service** (deep create of the HU hierarchy) or the standard HU API |
| FLP tile | inbound `HandlingUnit-packDyeingKejriwal` | Target mapping + tile (`docs/PUBLISHING.md`) |

### Backend (the critical dependency)

A **RAP/OData V4 service** that creates the nested handling units (cone inside
carton inside pallet) for the reference and stores net/gross weights, mapping to
the standard HU API where possible. The `onCreateHus` / `onRepack` `TODO`s in
`controller/Main.controller.js` mark where to wire it.

## ⚠️ Placeholders you MUST replace

1. `REPLACE_WITH_PACKING_SERVICE` (manifest `dataSources.mainService.uri`).
2. `REPLACE_WITH_ABAP_SYSTEM_URL` / client (`ui5.yaml`).
3. Property/entity names + the create payload must match the service.

## Run locally

```bash
npm install
npm start        # after replacing the REPLACE_WITH_* placeholders
```

## Publish

Deploys as a BSP (`npm run deploy`); own FLP tile via the
`HandlingUnit-packDyeingKejriwal` inbound. See
[`../../docs/PUBLISHING.md`](../../docs/PUBLISHING.md).

## Branch

Developed on `claude/fiori-app-extensions-h1nb64`.
