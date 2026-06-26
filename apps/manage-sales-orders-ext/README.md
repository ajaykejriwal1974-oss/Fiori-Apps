# F1873 – Manage Sales Orders · Adaptation Project

Clean-core **SAPUI5 Adaptation Project** that extends the standard SAP Fiori app
**F1873 – Manage Sales Orders** on **on-premise S/4HANA**, replacing the
customizations that used to live in the Z transaction `ZVA01 / ZVA01N`
(program `SAPMZ_SO_CREATE`) and the `ZSOCLOSE` order-close logic.

> Source of scope: `KEJRIWAL_Z_to_Fiori_Mapping.pdf`, Table B.

## What this project layers on top of the standard app

| Requested change | Implemented as | File |
|---|---|---|
| Custom UI section | `addXMLAtExtensionPoint` → XML fragment | `webapp/changes/fragments/TextileAttributes.fragment.xml` + `webapp/changes/id_*_addXMLTextileSection.change` |
| Custom fields (denier, shade, lustre, contract link) | Bindings inside the fragment | same fragment |
| Custom list column (shade) | Page-configuration change | `webapp/changes/manifest/id_*_addShadeColumn.change` |
| Controller extension / custom logic | `codeExt` controller extension | `webapp/changes/coding/SalesOrderObjectPageExt.js` + `webapp/changes/id_*_codeExt.change` |
| App variant descriptor | `manifest.appdescr_variant` | `webapp/manifest.appdescr_variant` |

## ⚠️ Placeholders you MUST replace

This scaffold is authored offline, so anything that can only come from your live
system is left as an explicit `REPLACE_WITH_*` token (kept deliberately invalid so
it can't ship by accident). Complete them in **SAP Business Application Studio →
Adaptation Editor**, which reads them from the running base app:

1. `REPLACE_WITH_BASE_APP_COMPONENT_ID` – the base app's SAPUI5 component id
   (a.k.a. `sap.app/id`). Find it in the **Fiori Apps Reference Library** entry for
   F1873, or in the deployed BSP `manifest.json` at
   `/sap/bc/ui5_ui5/sap/<bsp>/manifest.json`.
2. `REPLACE_WITH_BASE_APP_BSP_NAME` – the BSP application name of the base app.
3. `REPLACE_WITH_ABAP_SYSTEM_URL` / client – your Front-End Server.
4. `REPLACE_WITH_EXTENSION_POINT_NAME`, `REPLACE_WITH_OBJECT_PAGE_VIEW_ID`,
   `REPLACE_WITH_OBJECT_PAGE_CONTROLLER_NAME` – the real extension point / view /
   controller of the base Object Page. The Adaptation Editor lists these for you;
   do not guess them.
5. The field technical names (`YY1_Denier_SO`, `YY1_Shade_SO`, …) must match the
   actual extension fields exposed on the OData service.

## Backend prerequisites (not part of this UI project)

An adaptation project changes the **UI only**. Per the mapping doc, the data and
business logic are a separate, clean-core backend effort:

- **Custom fields** → custom CDS extension (extend/append on the Sales Order
  CDS) **or** key-user in-app field extensibility, then expose on the OData
  service consumed by F1873.
- **Pricing / availability / validation** (old `SAPMZ_SO_CREATE`) → a **released
  BAdI** for sales order processing, or a RAP determination/validation. The
  `onBeforeSave` hook here is only a client-side guard.
- **`ZSOCLOSE` order-close status** → custom status via status management / RAP +
  BAdI on the sales order. (Can be added to this project as further changes once
  the backend action exists.)
- **`ZDD_SHADE` shade master** → key-user Custom Business Object (RAP); drives the
  shade value help.

## Extensibility tier

Per SAP clean-core guidance, create the plain custom **fields** (denier, shade,
lustre, contract link) with **tier-1 key-user** *Custom Fields & Logic* where the
Sales Order supports it; this adaptation project (**tier 2**) owns the grouped
section, shade value help, and the `onBeforeSave` logic. See
[`docs/EXTENSIBILITY.md`](../../docs/EXTENSIBILITY.md).

## Run locally

```bash
npm install
npm start        # after replacing the REPLACE_WITH_* placeholders
```

## Branch

Developed on `claude/fiori-app-extensions-h1nb64`.
