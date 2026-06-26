# Manage Sales Contracts · Adaptation Project

Clean-core **SAPUI5 Adaptation Project** that extends the standard **Manage Sales
Contracts** Fiori app on **on-premise S/4HANA**, replacing the custom contract
lifecycle that used to live behind `ZCON_CLOSE / ZCON_CLOSE1 / ZCOREL / ZCON02`.

> Source of scope: `KEJRIWAL_Z_to_Fiori_Mapping.pdf`, Table B (base app shown as
> VA42 / F... — confirm the exact Fiori ID for "Manage Sales Contracts" in the
> Fiori Apps Reference Library for your FPS).

## What this project layers on top of the standard app

| Requested change | Implemented as | File |
|---|---|---|
| Custom UI section | `addXMLAtExtensionPoint` → XML fragment | `webapp/changes/fragments/ContractStatusActions.fragment.xml` + `webapp/changes/id_*_addXMLContractSection.change` |
| Pending-rate field + custom status display | Bindings inside the fragment | same fragment |
| Close / Release / Complete action buttons | Buttons → controller extension | same fragment + controller |
| Custom list column (status) | Page-configuration change | `webapp/changes/manifest/id_*_addStatusColumn.change` |
| Controller extension / action calls | `codeExt` controller extension | `webapp/changes/coding/SalesContractObjectPageExt.js` + `webapp/changes/id_*_codeExt.change` |
| App variant descriptor + FLP tile | `manifest.appdescr_variant` | `webapp/manifest.appdescr_variant` |

## ⚠️ The status logic is backend, not this app

The custom statuses (close / complete / release) are **not** implemented in the
UI. They are **status management / RAP** on the backend; the buttons here only
**trigger** the corresponding backend action (RAP action or function import
implemented via a released BAdI). The pending-rate is a **key-user field**.

## ⚠️ Placeholders you MUST replace

Complete in **SAP Business Application Studio → Adaptation Editor**:

1. `REPLACE_WITH_BASE_APP_FIORI_ID` – the Manage Sales Contracts Fiori ID.
2. `REPLACE_WITH_BASE_APP_COMPONENT_ID` – base app SAPUI5 component id (`sap.app/id`).
3. `REPLACE_WITH_BASE_APP_BSP_NAME` – BSP application name.
4. `REPLACE_WITH_ABAP_SYSTEM_URL` / client – your Front-End Server.
5. `REPLACE_WITH_EXTENSION_POINT_NAME`, `REPLACE_WITH_OBJECT_PAGE_VIEW_ID`,
   `REPLACE_WITH_OBJECT_PAGE_CONTROLLER_NAME` – real extension point / view /
   controller of the Object Page.
6. Field/entity names (`YY1_PendingRate_CON`, `YY1_KejStatus_CON`,
   `C_SalesContract`) must match the OData service.
7. The backend action call inside each `_runContractAction` (see controller TODO).

## Backend prerequisites (not part of this UI project)

- **Custom status** (close/complete/release) → status management / RAP status +
  released **BAdI** for the transitions.
- **Close / Release / Complete actions** → RAP actions or function imports the
  buttons call.
- **Pending rate** → key-user field on the contract, exposed on the OData service.
- **Contract batch update** (`ZBATCH_CHANGE`) is a separate, mass-update concern —
  better as a custom RAP action / app (like the inspection-results app), not part
  of this adaptation project.

## Run locally

```bash
npm install
npm start        # after replacing the REPLACE_WITH_* placeholders
```

## Branch

Developed on `claude/fiori-app-extensions-h1nb64`.
