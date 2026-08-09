# Custom (freestyle) Fiori apps — backend wiring plan

These are the **custom** apps (unmanaged RAP BOs with a behavior class that calls BAPIs),
distinct from the 13 master-data Fiori Elements apps. Their UIs are already deployed as BSPs.
Each needs its backend **imported (with the behavior class) → activated → verified against the
real tables → tested** on KSD. The behavior classes already contain drafted BAPI logic with
`VERIFY`-tagged spots for release-specific field/status names.

## App inventory

| App (folder) | Replaces | BAPI(s) it calls | Actions | Module | Complexity |
|---|---|---|---|---|---|
| **batch-status** | ZBATCH status | `BAPI_BATCH_CHANGE` | closeBatch, deleteBatch | Batch | 🟢 Low |
| **sales-doc-status** | ZSDSTAT | `BAPI_SALESDOCUMENT_CHANGE` | close/release contract, order, program | SD | 🟡 Medium |
| **contract-batch** | ZCTRBATCH | `BAPI_SALESDOCUMENT_CHANGE` | updateBatches | SD | 🟡 Medium |
| **dispatch-correction** | ZDISPATCH_CORR | *(direct update — verify)* | correctDispatch | SD/LE | 🟡 Medium |
| **hu-unpack** | ZHUUNPACK | `BAPI_HU_UNPACK` | unpackItems | LE/HU | 🟡 Medium |
| **packing-hu** | ZPACK | `BAPI_HU_CREATE`, `BAPI_HU_PACK` | createHandlingUnits | LE/HU | 🟡 Medium |
| **palletization** | ZPALLET | `BAPI_HU_CREATE`, `BAPI_HU_PACK` | packPallet | LE/HU | 🟡 Medium |
| **packing-detail** | ZPACKDET | `BAPI_HU_CREATE`, `BAPI_HU_PACK`, `BAPI_HU_REPACK_ITM` | packItems, repackItems | LE/HU | 🟠 Med-High |
| **hu-inbound** | ZINBGR | `BAPI_INB_DELIVERY_CONFIRM_DEC` | postInboundGr | LE | 🟠 Med-High |
| **qm-mass-results** | ZQA32 / ZQM_MASS_RESULT2 | `BAPI_INSPCHAR_SETRESULT`, `BAPI_INSPCHAR_CLOSE` | update (mass) | QM | 🟠 Med-High |
| **post-packing-gr** | ZPOST01 | `BAPI_GOODSMVT_CREATE` | postPackingAndGr | MM/Inv | 🔴 High |
| **goods-movement-hu** | ZGMHU | `BAPI_GOODSMVT_CREATE` | postGoodsMovement | MM/HU | 🔴 High |
| **mtos-process** | ZMTOS | `BAPI_GOODSMVT_CREATE`, `BAPI_MATPHYSINV_CREATE_MULT` | convertToMts, createPhysInvDoc | MM | 🔴 High |

### Not interactive Fiori apps (handle separately)
| po-automation | `ZCL_PO_AUTOMATION` — background/report class, no RAP BO |
| obd-automation | `ZCL_OBD_AUTOMATION` — background/report class, no RAP BO |
| minmax-master | empty in repo — not built |

## Why complexity varies
- 🟢 **Batch/status BAPIs** (`BAPI_BATCH_CHANGE`) — one object, few fields, easy to test on any batch.
- 🟡 **Sales doc / HU pack** — need a real sales doc / delivery / HU to test; BAPI structures are moderate.
- 🔴 **Goods movements** (`BAPI_GOODSMVT_CREATE`) — must get movement type, plant, storage location,
  special stock, and HU linkage exactly right; wrong config posts bad inventory. Highest test care.

## Recommended order

1. **Batch Status** (🟢) — first. Cleanest scope (2 actions), establishes the *import-with-behavior-class*
   pattern and gives a quick end-to-end win (import → activate → bind → publish → test on a real batch).
2. **Sales Doc Status** + **Contract Batch** (🟡, both `BAPI_SALESDOCUMENT_CHANGE`) — reuse the SD pattern.
3. **HU cluster** — packing-hu, palletization, hu-unpack, packing-detail (🟡–🟠, shared `BAPI_HU_*`) — do together.
4. **QM Mass Results** (🟠) — needs QM configured + a live inspection lot to test.
5. **Goods-movement group** — post-packing-gr, goods-movement-hu, mtos-process (🔴) — last, most care.
6. **po-automation / obd-automation** — separate track (background jobs, not RAP apps).

## Per-app procedure (repeat for each)
1. I prepare the app's abapGit import bundle (CDS + `zd_*` action entities + **behavior class** + service).
2. You pull it into `ZKGPL_FIORI` and activate — field/status mismatches vs your real tables surface here.
3. I fix the mismatches (the `VERIFY` spots) from your feedback.
4. Create the OData V4 binding, publish (after the Gateway gate), and **you test the action** on real data.
5. Iterate until the action posts correctly.
