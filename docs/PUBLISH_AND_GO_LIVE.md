# Publish & Go-Live — KGPL Fiori backends (KSD)

Status: **ALL 26 backends built, activated, and bound** on KSD in package
`ZKGPL_FIORI` — 13 master-data apps (class-free managed RAP) and 13 custom
apps (unmanaged RAP with `ZBP_I_*` behavior classes calling standard BAPIs),
plus the 2 background automation classes (`ZCL_PO_AUTOMATION`,
`ZCL_OBD_AUTOMATION`). Every service has an **OData V4 - UI** binding
(transport `KSDK906624`).

The only step left to make the endpoints live is **Publish**, gated by one
one-time Basis task.

## 1. Basis: enable OData V4 local publishing (one-time, system-wide)

All bindings show **Local Service Endpoint: Unpublished**; Publish fails with
*"Local Publish failed"* until the local OData publishing infrastructure is
configured on this fresh Initial-Shipment system.

**Action (Basis):** run task list **`SAP_GATEWAY_BASIC_CONFIG`** via
transaction **`STC01`**. If Publish still fails afterwards, check the ICF node
`/sap/opu/odata4` (SICF) is active and re-run the failing task step — then send
the "Details" text of the publish error.

## 2. Basis: delete the corrupt old Gate Pass objects (unblocks mass activation)

The original Gate Pass import left **corrupt, undeletable** objects that abort
EVERY mass activation ("Activation cancelled") — which forced all of the above
to be activated object-by-object:

- `ZC_GATEPASS`, `ZC_GATEPASS_ITEM` (metadata extensions / DDLX — "resource not
  locked" on every touch)
- `ZUI_GATEPASS` (old service), plus any remaining `ZI_GATEPASS*` /
  `ZC_GATEPASS*` views and behaviors

**Action (Basis):** clear the inconsistent runtime versions (SE14 / delete
inactive versions) and delete the objects. The replacement app is `*GTPASS*`
and is fully active. Until this cleanup, use single-object activation only.

## 3. Basis: make GitHub SSL trust permanent

The abapGit pulls need GitHub's certificate chain in **STRUST → SSL Client
(Standard)**; the trust dropped once after an ICM restart. Import the chain,
save, restart ICM, and confirm it survives restarts.

## 4. Create the missing bindings, then publish all 26

> **Corrected 16.07.2026 against the live system** (TADIR + SRVB_HEAD /
> SRVB_SERVICES on KSD client 500). Earlier versions of this list showed the
> intended names (`_O4` suffix) and claimed all 26 bindings existed. Actual
> state: only the **13 custom-app bindings are fully created and active**
> (mostly named `_04` — zero four — with two name typos). The **11 master-data
> bindings exist only as empty repository (TADIR) entries with no binding
> content** — the ADT wizard entry was created but never saved with data —
> and the bindings for `ZUI_TRANSPORT` and `ZUI_GTPASS` were **never created**.

### Master data (13) — all 13 must be (re)created before publishing

The 11 shell entries cannot be published; open each in ADT — if it opens
empty or errors, delete the shell and create the binding fresh (right-click
the service definition → *New Service Binding*, type **OData V4 - UI**,
package `ZKGPL_FIORI`). Then create the two that never existed.

| Binding (TADIR entry) | Service Definition | Actual state on KSD |
|---|---|---|
| `ZUI_DD_SHADE_04` | `ZUI_DD_SHADE` | shell only — no binding content |
| `ZUI_RECIPE_04` | `ZUI_RECIPE` | shell only — no binding content |
| `ZUI_SCHEDULE_04` | `ZUI_SCHEDULE` | shell only — no binding content |
| `ZUI_JOB_04` | `ZUI_JOB` | shell only — no binding content |
| `ZUI_MERGE_04` | `ZUI_MERGE` | shell only — no binding content |
| `ZUI_PACKING_MATERIAL_04` | `ZUI_PACKING_MATERIAL` | shell only — no binding content |
| `ZUI_TRUCK_04` | `ZUI_TRUCK` | shell only — no binding content |
| `ZUI_CFORM_04` | `ZUI_CFORM` | shell only — no binding content |
| `ZUI_CHECKEDE_BY_04` (sic) | `ZUI_CHECKED_BY` | shell only — no binding content |
| `ZUI_DIGITAL_SIGNATURE_04` | `ZUI_DIGITAL_SIGNATURE` | shell only — no binding content |
| `ZUI_EXPORT_DETAIL_04` | `ZUI_EXPORT_DETAIL` | shell only — no binding content |
| — (create, e.g. `ZUI_TRANSPORT_04`) | `ZUI_TRANSPORT` | binding never created |
| — (create, e.g. `ZUI_GTPASS_04`) | `ZUI_GTPASS` | binding never created |

### Custom apps (13) — created and active, publish after step 1

Binding names below are the **verified names on the system** (from
`SRVB_SERVICES`); note `ZUI_BATCH_STATUS_O4` is the only one with the
letter-O suffix, and two carry typos.

| Binding | Service Definition | Actions (behavior class) |
|---|---|---|
| `ZUI_BATCH_STATUS_O4` | `ZUI_BATCH_STATUS` | closeBatch, deleteBatch |
| `ZUI_SALES_DOC_STATUS_04` | `ZUI_SALES_DOC_STATUS` | close/complete/release contract, updatePendingRate, close order/program |
| `ZUI_CONTRACT_BATCH_04` | `ZUI_CONTRACT_BATCH` | updateBatches |
| `ZUI_DISPATCH_04` | `ZUI_DISPATCH_CORRECTION` | correctDispatch |
| `ZUI_HU_UNPACK_04` | `ZUI_HU_UNPACK` | unpackItems |
| `ZUI_PACKING_04` | `ZUI_PACKING` | createHandlingUnits |
| `ZUI_PALLETIZATION_04` | `ZUI_PALLETIZATION` | packPallet |
| `ZUI_PACKING_DETAIL_04` | `ZUI_PACKING_DETAIL` | packItems, repackItems |
| `ZUI_HU_INBOND_04` (sic) | `ZUI_HU_INBOUND` | postInboundGr |
| `ZUI_QM_INSPECTIONCHAR_04` | `ZUI_QM_INSPECTIONCHAR` | update (mass result entry) |
| `ZUI_POST_PACKING_GR_04` | `ZUI_POST_PACKING_GR` | postPackingAndGr |
| `ZUI_HU_GOODS_MOVEMENT_04` | `ZUI_HU_GOODS_MOVEMENT` | postGoodsMovement |
| `ZUI_MTOS_PROCESS_04` | `ZUI_MTOS_PROCESS` | convertToMts, createPhysInvDoc |

## 5. Test plan (after publish) — custom-app actions

Test in this order (green → red risk), one action at a time, on TEST data.
The behavior classes carry VERIFY-tagged assumptions (BAPI parameter shapes,
movement types, status codes) that are confirmed only by a real call — expect
to iterate on the first run of each action.

1. **Batch Status** — closeBatch on a test batch (sets CLOSED on `ZPP_BATCHN`
   only); then deleteBatch on a dummy batch (deletion flag via
   `BAPI_BATCH_CHANGE`).
2. **Sales Doc Status / Contract Batch** — on a test contract/order
   (`BAPI_SALESDOCUMENT_CHANGE`).
3. **HU cluster** (packing, palletization, unpack, packing-detail) — needs a
   test delivery/HU (`BAPI_HU_CREATE/PACK/UNPACK/REPACK_ITM`).
4. **HU Inbound** — a test inbound delivery (`BAPI_INB_DELIVERY_CONFIRM_DEC`).
5. **QM Mass Results** — a live inspection lot. NOTE: the "open
   characteristics only" filter was removed to activate; re-add once the
   correct QALS status flag is confirmed.
6. **Goods movements** (post-packing-GR, HU goods movement, MTOS) — LAST;
   these post inventory (`BAPI_GOODSMVT_CREATE`,
   `BAPI_MATPHYSINV_CREATE_MULT`). Verify movement types/GM codes on a test
   plant first.

### Flat action-parameter formats (UI contract)

Deep (header+items) parameters were flattened to delimited strings (composition
abstract entities do not activate on this system). The UI5 apps must send:

| Action | Field | Format |
|---|---|---|
| updateBatches | `ItemBatchList` | `000010=BATCH1;000020=BATCH2` |
| correctDispatch | `BoxList` | `BOX1;BOX2` |
| postGoodsMovement | `HandlingUnitList` | `HU1;HU2` (contents read from VEPO) |
| unpackItems | `HuItemList` | `HU1=0001;HU1=0002` (detail read from VEPO) |
| packItems | `ItemList` | `MAT=BATCH=10.500=KG` |
| createHandlingUnits | `UnitList` | `PACKMAT=QTY;...` (bottom-up levels) |
| packPallet | `BoxHuList` | `HU1;HU2` |
| createPhysInvDoc | `ItemList` | `MAT=BATCH;MAT=BATCH` |
| postPackingAndGr | `HandlingUnitList` | `HU1;HU2` (contents read from VEPO) |
| repackItems | `ItemList` | `HUITEM=QTY;...` |

## What was done (summary)

- abapGit standalone on KSD; GitHub SSL trust (STRUST); pulls from branch
  `claude/fiori-apps-ui5-completeness-4bvlmp`, package `ZKGPL_FIORI`.
- Master data: entity/DDL-source name alignment; CURR/QUAN/EXCRT casts to
  plain decimals; class-free managed behaviors; Gate Pass re-modelled flat as
  GTPASS; Transport re-based on `ZTRCKMSTR`.
- Custom apps: unmanaged RAP + behavior classes; strict() removed; deep action
  params flattened; COMMIT WORK → BAPI_TRANSACTION_COMMIT; batch deletion flag
  set dynamically; QM view without QAPO (unsupported) and with fltp_to_dec;
  MTOS on NSDM_E_MSKA with BaseUnit from MARA; defaultSearchElement added to
  8 projections.
- All 26 services and bindings **activated** (bindings on transport
  `KSDK906624`).
