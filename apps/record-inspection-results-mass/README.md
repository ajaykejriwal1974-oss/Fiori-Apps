# F2655 / ZQA32 – Record Inspection Results (Mass) · Custom Fiori App

A **custom freestyle SAPUI5 app** for **mass / multi-lot inspection result
entry**, the clean-core replacement for `ZQA32`.

> Source of scope: `KEJRIWAL_Z_to_Fiori_Mapping.pdf`, Table B.

## ⚠️ Why this is NOT an adaptation project

The standard app **F2655 – Record Inspection Results** records results **one
inspection lot at a time**. Your requirement (from `ZQA32`) is **mass entry
across many lots at once**. That is a different interaction model, not a UI tweak
— so an adaptation project on F2655 cannot deliver it. Per the mapping doc, the
clean-core option is a **custom Fiori app (RAP) over the QM results API** (this
app), or keep `QA32` via Screen Personas. This is the RAP/custom-app route.

## What it does

- A worklist with a **broad filter bar** (plant / work center / inspection lot).
- An **editable, multi-select table** of all open inspection characteristics
  across the selected lots — enter a **result value** and **valuation
  (Accept/Reject)** per row.
- A **Post Results** action that submits all edited rows in **one batch**.
- Tracks edited rows (`dirtyCount`) and only posts those.

## Architecture

| Layer | This repo | To build |
|---|---|---|
| UI (freestyle UI5) | `webapp/` (Component, Worklist view+controller, i18n) | — |
| OData V4 service | declared in `manifest.json` (`mainService`) | **Custom RAP service** over the QM result-recording API |
| FLP tile | inbound `InspectionResult-recordMassKejriwal` in `manifest.json` | Target mapping + tile (see `docs/PUBLISHING.md`) |

### Backend service (the critical dependency)

This app needs an OData V4 service exposing the inspection characteristics to
record and accepting mass updates. Build it as a **RAP service** over the QM
result-recording API (e.g. the result-recording BAPIs / released QM APIs such as
inspection-lot & characteristic results). The app expects, at minimum, an
`InspectionCharacteristic` entity with: `InspectionLot`, `Material`, `Plant`,
`WorkCenter`, `CharacteristicDescription`, `ResultValue`, `Unit`, `Valuation`,
and either updatable properties or a bound **mass-post action**.

> A RAP **skeleton** for this service is authored at
> [`backend/qm-mass-results-rap`](../../backend/qm-mass-results-rap) (unmanaged
> BO: read CDS over QM + `update`/`save` that records via the QM BAPI). Point
> `REPLACE_WITH_QM_MASS_SERVICE` at its service binding `ZUI_QM_INSPECTIONCHAR`.

## ⚠️ Placeholders you MUST replace

1. `REPLACE_WITH_QM_MASS_SERVICE` (manifest `dataSources.mainService.uri`) – the
   technical name of your custom RAP OData V4 service.
2. `REPLACE_WITH_ABAP_SYSTEM_URL` / client (`ui5.yaml`) – your Front-End Server.
3. Entity/property names in the view + controller must match the service.
4. If the backend uses a dedicated mass-post **action** instead of plain
   updatable fields, replace the `submitBatch` call in
   `controller/Worklist.controller.js#onPostResults` with the bound action call.

## Run locally

```bash
npm install
npm start        # after replacing the REPLACE_WITH_* placeholders
```

## Publish

Deploys as a BSP (`npm run deploy`) and gets its own FLP tile via the
`InspectionResult-recordMassKejriwal` inbound. See
[`../../docs/PUBLISHING.md`](../../docs/PUBLISHING.md).

## Branch

Developed on `claude/fiori-app-extensions-h1nb64`.
