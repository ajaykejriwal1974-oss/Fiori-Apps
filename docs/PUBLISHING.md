# Deploying & launching the adaptation projects in the Fiori Launchpad (on-premise)

End-to-end path to get each app variant in this repo deployed to the **embedded
Front-End Server (FES)** and visible as its **own tile** on the on-premise
S/4HANA Fiori Launchpad. Each app keeps the standard SAP app available and adds a
separate KEJRIWAL tile (via a new launchpad inbound in its
`manifest.appdescr_variant`).

## 0. Prerequisites

- Placeholders (`REPLACE_WITH_*`) in `ui5.yaml` and `manifest.appdescr_variant`
  filled from the live system (base app component id, ABAP system URL, BSP name,
  extension points). Use the **BAS Adaptation Editor** to discover them.
- Base app's OData service activated (`/IWFND/MAINT_SERVICE`), system alias OK.
- Custom backend fields (custom CDS / key-user) exist and are exposed on the
  OData service before binding them in the UI.

## 1. Preview locally

```bash
npm install
npm start        # merged base app + your changes, via fiori-tools-proxy
```

## 2. Deploy to the Front-End Server

```bash
npm run deploy   # fiori deploy -> SAPUI5 ABAP repository (BSP) on the FES
```

- Creates/updates the **app variant** (BSP) that references the base app.
- **Transport:** change `"packageName": "$TMP"` to a real package + attach a
  workbench transport request to move FES-Dev -> QA -> PROD. `$TMP` is local only.

## 3. Each app's launchpad intent (new inbound)

| App | Fiori ID | Intent (semantic object - action) | Tile title |
|---|---|---|---|
| Manage Sales Orders | F1873 | `SalesOrder-manageKejriwal` | Manage Sales Orders (Textile) |
| Confirm Production Operation | F3069 | `ProductionOrderConfirmation-manageKejriwal` | Confirm Production Operation (Dyeing) |
| Manage Outbound Deliveries | F0867A | `OutboundDelivery-manageKejriwal` | Manage Outbound Deliveries (Challan) |

These intents are defined via `appdescr_app_addNewInbound` in each
`manifest.appdescr_variant`, so the variant is launchable on its own without
overriding the standard app.

## 4. Create launchpad content

Use whichever content model your system runs:

**Classic catalogs** - `/UI2/FLPD_CUST` (Launchpad Designer):
1. Create / extend a **catalog**.
2. Add a **Target Mapping** for the intent above, pointing to the app variant's
   UI5 component / app id.
3. Add a **Tile** (static or dynamic) bound to that intent.

**Spaces & Pages** (S/4HANA 2023+ default) - **Launchpad Content Manager**:
1. Create the catalog and add the app by its intent.
2. Add the tile to a **page**, assign the page to a **space**.

## 5. Assign to users

- `PFCG`: create/extend a **role**, add the catalog (and group/space/page),
  assign the role to users.
- Invalidate caches: `/UI2/INVALIDATE_GLOBAL_CACHE`, then re-login.

## 6. Backend artifacts that are NOT in these UI projects

- Custom fields -> custom CDS extension / in-app key-user extensibility.
- Business logic (pricing/validation, order/contract close, batch & WIP updates)
  -> released BAdI or RAP determination/validation.
- Delivery challan print -> Output Management output type + Adobe form.
- Shade master (ZDD_SHADE) -> RAP Custom Business Object.
