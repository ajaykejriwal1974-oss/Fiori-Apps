# F0867A – Manage Outbound Deliveries · Adaptation Project

Clean-core **SAPUI5 Adaptation Project** that extends the standard SAP Fiori app
**F0867A – Manage Outbound Deliveries** on **on-premise S/4HANA**, replacing the
delivery-challan customization that used to live behind `ZDEL`
(program `ZRPT_DELIVERY_CHALLAN`).

> Source of scope: `KEJRIWAL_Z_to_Fiori_Mapping.pdf`, Table B.

## What this project layers on top of the standard app

| Requested change | Implemented as | File |
|---|---|---|
| Custom UI section | `addXMLAtExtensionPoint` → XML fragment | `webapp/changes/fragments/DeliveryChallan.fragment.xml` + `webapp/changes/id_*_addXMLChallanSection.change` |
| Custom fields (challan no/date, vehicle, transporter, e-way bill) | Bindings inside the fragment | same fragment |
| Custom list column (challan no) | Page-configuration change | `webapp/changes/manifest/id_*_addChallanColumn.change` |
| Controller extension + "Print Challan" action | `codeExt` controller extension | `webapp/changes/coding/OutboundDeliveryObjectPageExt.js` + `webapp/changes/id_*_codeExt.change` |
| App variant descriptor | `manifest.appdescr_variant` | `webapp/manifest.appdescr_variant` |

## ⚠️ The challan PRINT is Output Management, not this app

The old `ZRPT_DELIVERY_CHALLAN` print logic is **not** re-implemented here. The
clean-core replacement is an **Output Management** (BRF+) determination on the
outbound delivery that renders an **Adobe form** (e.g. output type `ZCHALLAN`).
The "Print Delivery Challan" button in this project only **triggers** that
output; the form design and determination are separate backend configuration.

## ⚠️ Placeholders you MUST replace

Authored offline; every live-system value is an explicit `REPLACE_WITH_*` token
(kept deliberately invalid). Complete them in **SAP Business Application Studio →
Adaptation Editor**:

1. `REPLACE_WITH_BASE_APP_COMPONENT_ID` – base app SAPUI5 component id (`sap.app/id`).
2. `REPLACE_WITH_BASE_APP_BSP_NAME` – BSP application name.
3. `REPLACE_WITH_ABAP_SYSTEM_URL` / client – your Front-End Server.
4. `REPLACE_WITH_EXTENSION_POINT_NAME`, `REPLACE_WITH_OBJECT_PAGE_VIEW_ID`,
   `REPLACE_WITH_OBJECT_PAGE_CONTROLLER_NAME` – real extension point / view /
   controller of the Object Page.
5. Field technical names (`YY1_ChallanNo_DEL`, `YY1_VehicleNo_DEL`, …) must match
   the actual delivery extension fields on the OData service.
6. The Output Management output type / API call inside `onPrintDeliveryChallan`.

## Backend prerequisites (not part of this UI project)

- **Custom delivery fields** → in-app key-user field extensibility / custom CDS
  on the outbound delivery, exposed on the OData service.
- **Challan print** → Output Management output type + Adobe form (replaces
  `ZRPT_DELIVERY_CHALLAN`).

## Extensibility tier

Per SAP clean-core guidance, create the plain custom **fields** (challan no/date,
vehicle, transporter, e-way bill) with **tier-1 key-user** *Custom Fields & Logic*
on the outbound delivery; this adaptation project (**tier 2**) owns the grouped
section, the "Print Challan" action, and the `onBeforeSave` guard. See
[`docs/EXTENSIBILITY.md`](../../docs/EXTENSIBILITY.md).

## Run locally

```bash
npm install
npm start        # after replacing the REPLACE_WITH_* placeholders
```

## Branch

Developed on `claude/fiori-app-extensions-h1nb64`.
