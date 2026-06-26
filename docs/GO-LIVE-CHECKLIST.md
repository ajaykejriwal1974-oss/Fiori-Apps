# Go-Live Checklist (per app)

Execute **one app at a time**. For each: (A) collect placeholder values,
(B) build/confirm the backend, (C) deploy, (D) publish the tile, (E) verify.
Gate: the base app must already be **activated** by Basis (see
[`ACTIVATION.md`](ACTIVATION.md)). Target: KSQ/KHQ, **client 500**.

Recommended first app: **F1873 Manage Sales Orders** (cleanest adaptation
project) — prove the template end-to-end, then repeat for the rest.

---

## Shared procedures (referenced below)

### S1 · Find the base app technical details (adaptation projects)
In **SAP Business Application Studio → Adaptation Editor**, open the project
against the live system. The editor lists the real values for:
- `REPLACE_WITH_BASE_APP_COMPONENT_ID` — base app `sap.app/id`
  (also in Fiori Apps Reference Library, or the BSP `manifest.json`).
- `REPLACE_WITH_BASE_APP_BSP_NAME` — base app BSP name.
- `REPLACE_WITH_EXTENSION_POINT_NAME` and the Object Page
  `..._VIEW_ID` / `..._CONTROLLER_NAME`.

### S2 · Set the destination
Set `REPLACE_WITH_ABAP_SYSTEM_URL` (per developer/BAS destination). Client is
already `500` in every `ui5.yaml`.

### S3 · Deploy
```bash
npm install
npm start     # preview against the live base app (adaptation) or service (custom)
npm run deploy   # fiori deploy -> SAPUI5 ABAP repository (BSP) on the FES
```
Change `"packageName": "$TMP"` (adaptation descriptors) to a real package +
workbench transport before moving beyond the sandbox.

### S4 · Publish the FLP tile
Create a **target mapping + tile** for the app's intent (table below) and add it
to a **catalog** (Launchpad Designer `/UI2/FLPD_CUST`) or **space/page**
(Launchpad Content Manager). Assign the catalog to the **business role** in PFCG.
Full steps in [`PUBLISHING.md`](PUBLISHING.md).

### S5 · Verify
- App preview/launch loads and returns data.
- Custom fields/sections render; actions/buttons behave.
- `/IWFND/ERROR_LOG` clean; `/UI2/INVALIDATE_GLOBAL_CACHE` then re-login if needed.

---

## Adaptation projects

### F1873 · Manage Sales Orders — `apps/manage-sales-orders-ext`
- Intent: `SalesOrder-manageKejriwal` · Role: `SAP_BR_INTERNAL_SALES_REP`
- [ ] **A** S1 placeholders + S2 destination
- [ ] **A** Field names match the service: `YY1_Denier_SO`, `YY1_Shade_SO`,
      `YY1_Lustre_SO`, `YY1_ContractRef_SO`; entity `C_SalesOrder`
- [ ] **B** Backend: custom fields via tier-1 Custom Fields & Logic (see
      [`EXTENSIBILITY.md`](EXTENSIBILITY.md)); pricing/validation + ZSOCLOSE
      order-close via released BAdI / RAP
- [ ] **C** S3 deploy · **D** S4 publish · **E** S5 verify

### F3069 · Confirm Production Operation — `apps/confirm-production-operation-ext`
- Intent: `ProductionOrderConfirmation-manageKejriwal` · Role: `SAP_BR_PRODN_OPERATOR`
- [ ] **A** S1 placeholders (`..._CONFIRMATION_VIEW_ID` / `..._CONTROLLER_NAME`) + S2
- [ ] **A** ⚠️ Confirm framework: **FE vs freestyle** (production confirmation is
      often freestyle — adjust the `onBeforeSave` hook to the real post handler)
- [ ] **A** Fields: `YY1_Shade_CONF`, `YY1_DyeLot_CONF`, `YY1_Recipe_CONF`,
      `YY1_Temperature_CONF`, `YY1_WIPBatch_CONF`
- [ ] **B** Backend: fields (tier-1 if supported, else CDS extend); dyeing logic
      + WIP batch update via BAdI / RAP
- [ ] **C** S3 · **D** S4 · **E** S5

### F0867A · Manage Outbound Deliveries — `apps/manage-outbound-deliveries-ext`
- Intent: `OutboundDelivery-manageKejriwal` · Role: `SAP_BR_SHIPPING_SPECIALIST`
- [ ] **A** S1 placeholders + S2
- [ ] **A** Fields: `YY1_ChallanNo_DEL`, `YY1_ChallanDate_DEL`,
      `YY1_VehicleNo_DEL`, `YY1_Transporter_DEL`, `YY1_EwayBillNo_DEL`; entity
      `C_OutboundDelivery`
- [ ] **B** Backend: delivery custom fields (tier-1); **challan print = Output
      Management output type `ZCHALLAN` + Adobe form**; wire the output call in
      `onPrintDeliveryChallan`
- [ ] **C** S3 · **D** S4 · **E** S5

### Manage Sales Contracts — `apps/manage-sales-contracts-ext`
- Intent: `SalesContract-manageKejriwal` · Role: `SAP_BR_INTERNAL_SALES_REP`
- [ ] **A** S1 placeholders **+ `REPLACE_WITH_BASE_APP_FIORI_ID`** (confirm the
      Manage Sales Contracts F-ID for your FPS) + S2
- [ ] **A** Fields: `YY1_PendingRate_CON`, `YY1_KejStatus_CON`; entity `C_SalesContract`
- [ ] **B** Backend: custom status (status mgmt / RAP) + Close/Release/Complete
      **actions**; wire each `_runContractAction` call; rate = tier-1 field
- [ ] **C** S3 · **D** S4 · **E** S5

---

## Custom Fiori apps (need a custom backend service first)

> For these, **B (build the backend RAP/OData V4 service) is the long pole**.
> The UI is done; wire the controller `TODO`s to the service, then deploy.

### Record Inspection Results (Mass) — `apps/record-inspection-results-mass`
- Intent: `InspectionResult-recordMassKejriwal` · Role: `SAP_BR_QUALITY_TECHNICIAN`
- [ ] **A** `REPLACE_WITH_QM_MASS_SERVICE` + S2
- [ ] **B** Build RAP service from the skeleton at `backend/qm-mass-results-rap`
      (`InspectionCharacteristic` entity, unmanaged update/save over the QM
      result-recording BAPI); complete the QM `TODO`/`VERIFY` items + service
      binding `ZUI_QM_INSPECTIONCHAR`
- [ ] **C** S3 · **D** S4 · **E** S5

### Post Goods Movement (HU / Box) — `apps/post-goods-movement-hu`
- Intent: `MaterialDocument-postHuKejriwal` · Role: `SAP_BR_INVENTORY_MANAGER`
- [ ] **A** `REPLACE_WITH_HU_GM_SERVICE` + S2
- [ ] **B** Build RAP service from the skeleton at `backend/goods-movement-hu-rap`
      (HU read + `postGoodsMovement` static action → BAPI_GOODSMVT_CREATE);
      complete the `TODO`/`VERIFY` + binding `ZUI_HU_GOODS_MOVEMENT`; wire
      `onScanHu` + `onPostMovement`
- [ ] **C** S3 · **D** S4 · **E** S5

### Dyeing Packing — `apps/dyeing-packing`
- Intent: `HandlingUnit-packDyeingKejriwal` · Role: `SAP_BR_WAREHOUSE_CLERK`
- [ ] **A** `REPLACE_WITH_PACKING_SERVICE` + S2
- [ ] **B** First check standard **HU Management + packing instructions** can model
      cone/carton/pallet; else build the RAP service from the skeleton at
      `backend/packing-hu-rap` (`createHandlingUnits` → BAPI_HU_CREATE/PACK,
      binding `ZUI_PACKING`); wire `onCreateHus`
- [ ] **C** S3 · **D** S4 · **E** S5

### Contract Batch Update — `apps/contract-batch-update`
- Intent: `SalesContract-updateBatchKejriwal` · Role: `SAP_BR_INTERNAL_SALES_REP`
- [ ] **A** `REPLACE_WITH_CONTRACT_BATCH_SERVICE` + S2
- [ ] **B** Build RAP service from the skeleton at `backend/contract-batch-rap`
      (contract-items read + `updateBatches` action → BAPI_SALESDOCUMENT_CHANGE,
      binding `ZUI_CONTRACT_BATCH`); wire `onLoadContract` + `onUpdateBatches`
- [ ] **C** S3 · **D** S4 · **E** S5

---

## Backend object

### Shade Master (RAP CBO) — `backend/shade-master-rap`
Build this **early** — it provides the shade value help for F1873 & F3069.
- [ ] Create DB table `zdd_shade` (per `src/zdd_shade.table-spec.md`)
- [ ] Import `src/` objects into ADT; activate in order: table → `ZI_DD_Shade` →
      `ZC_DD_Shade` → behavior defs → behavior class → metadata ext → service def
- [ ] Create + activate service binding `ZUI_DD_SHADE_O4` (OData V4 – UI)
- [ ] (Optional) publish the generated "Manage Shades" Fiori Elements app
- [ ] Wire `onShadeValueHelp` in F1873 & F3069 to the shade service
- [ ] Alternative: build the same as a **tier-1 key-user Custom Business Object**

---

## Suggested sequence

1. **Shade Master** (unblocks value helps) →
2. **F1873** (prove the adaptation template) →
3. F3069, F0867A, Manage Sales Contracts (remaining adaptations) →
4. Custom apps, each after its backend service is built.
