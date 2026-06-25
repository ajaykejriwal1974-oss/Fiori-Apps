# F3069 – Confirm Production Operation · Adaptation Project

Clean-core **SAPUI5 Adaptation Project** that extends the standard SAP Fiori app
**F3069 – Confirm Production Operation** on **on-premise S/4HANA**, replacing the
dyeing-confirmation customization that used to live behind `ZCO11N / ZCO11A`.

> Source of scope: `KEJRIWAL_Z_to_Fiori_Mapping.pdf`, Table B.

## What this project layers on top of the standard app

| Requested change | Implemented as | File |
|---|---|---|
| Custom UI section | `addXMLAtExtensionPoint` → XML fragment | `webapp/changes/fragments/DyeingConfirmation.fragment.xml` + `webapp/changes/id_*_addXMLDyeingSection.change` |
| Custom fields (shade, dye-lot, recipe, temperature, WIP batch) | Bindings inside the fragment | same fragment |
| Controller extension / custom logic | `codeExt` controller extension | `webapp/changes/coding/ProductionConfirmationExt.js` + `webapp/changes/id_*_codeExt.change` |
| App variant descriptor | `manifest.appdescr_variant` | `webapp/manifest.appdescr_variant` |

> Note: unlike the F1873 project, there is **no `changePageConfiguration` column
> change** here. That change type is Fiori-Elements-only; F3069 is typically a
> freestyle SAPUI5 app, so the section is injected purely via the XML fragment.
> Confirm the framework in the Adaptation Editor.

## ⚠️ Placeholders you MUST replace

Authored offline, so anything that can only come from the live system is left as
an explicit `REPLACE_WITH_*` token (kept deliberately invalid). Complete them in
**SAP Business Application Studio → Adaptation Editor**:

1. `REPLACE_WITH_BASE_APP_COMPONENT_ID` – the base app's SAPUI5 component id
   (`sap.app/id`). From the Fiori Apps Reference Library entry for F3069 or the
   deployed BSP `manifest.json`.
2. `REPLACE_WITH_BASE_APP_BSP_NAME` – the BSP application name.
3. `REPLACE_WITH_ABAP_SYSTEM_URL` / client – your Front-End Server.
4. `REPLACE_WITH_EXTENSION_POINT_NAME`, `REPLACE_WITH_CONFIRMATION_VIEW_ID`,
   `REPLACE_WITH_CONFIRMATION_CONTROLLER_NAME` – the real extension point / view /
   controller of the confirmation screen (the editor lists them).
5. The field technical names (`YY1_Shade_CONF`, `YY1_DyeLot_CONF`, …) must match
   the actual extension fields on the OData service.
6. The controller hook used here is `onBeforeSave`. If F3069 is freestyle, change
   it to the app's real post/confirm handler.

## Backend prerequisites (not part of this UI project)

- **Custom fields** → custom CDS extension on the production confirmation entity
  (or key-user in-app field extensibility), exposed on the OData service.
- **Dyeing confirmation logic & WIP batch update** → released **BAdI** or **RAP**
  determination/validation. The `onBeforeSave` guards here are client-side only.
- **Shade master** (`ZDD_SHADE`) → key-user Custom Business Object (RAP); drives
  the shade value help.

## Extensibility tier

Per SAP clean-core guidance, create the plain custom **fields** (shade, dye-lot,
recipe, temperature, WIP batch) with **tier-1 key-user** *Custom Fields & Logic*
**if** the production confirmation entity supports it (verify — it may not; fall
back to a tier-2 CDS extend). This adaptation project (**tier 2**) owns the
grouped section and guards. See
[`docs/EXTENSIBILITY.md`](../../docs/EXTENSIBILITY.md).

## Run locally

```bash
npm install
npm start        # after replacing the REPLACE_WITH_* placeholders
```

## Branch

Developed on `claude/fiori-app-extensions-h1nb64`.
