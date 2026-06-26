# ADT activation checklist — the four system-side follow-ups

Everything in this repo is merged, structurally CI-validated, and clean-core (no
SAP standard object is modified). What remains can only be done **with ADT access
to KSQ/KHQ, client 500** — it cannot be done from the repo. This is the punch
list for the four follow-ups, in the order they must actually run.

> Context docs (don't duplicate, read alongside):
> [`ACTIVATION.md`](ACTIVATION.md) (Basis ↔ Dev order),
> [`WIRING-CHECKLIST.md`](WIRING-CHECKLIST.md) (placeholder inventory),
> [`TRANSPORT-PLAN.md`](TRANSPORT-PLAN.md), per-app [`GO-LIVE-CHECKLIST.md`](GO-LIVE-CHECKLIST.md).

## How the four follow-ups interleave

They are **not** four independent passes — #3 happens *inside* #2, and #1 depends
on #2 completing. Real execution order:

```
FU#2  Activate the ABAP repository objects (CDS → BDEF → behavior pool → SRVD)
        └─ FU#3  Confirm each VERIFY marker — wrong DDIC field/struct names
                 surface HERE as activation errors on the unmanaged pools
FU#1  Create + activate one OData V4 service binding per SRVD, then fill the
        manifest URI + controller SERVICE_NS with the published binding name
FU#4  ATC clean run, then publish the Fiori tiles / assign catalogs & roles
```

Object inventory to be activated: **123** CDS views (`ZI_*` interface + `ZC_*`
projection), **52** behavior definitions, **28** behavior pool classes, **26**
service definitions, **0** metadata extensions, **0** DCL (none authored — see
note in FU#4). Split: **13 managed master** services, **13 unmanaged
transactional** services.

---

## FU#2 — Activate the CDS / behavior / service objects (do first)

Activate in strict dependency order. In ADT, activating a projection auto-pulls
its interface view, but activate bottom-up the first time so errors are local.

1. **Interface CDS views** `ZI_*` (`*.ddls.asddls`) — these sit over the existing
   legacy `Z*` tables and released `I_*` views. Mass-select → Activate.
2. **Projection CDS views** `ZC_*` — depend on (1).
3. **Interface behavior definitions** `ZI_*.bdef.asbdef`.
4. **Behavior pool classes** `ZBP_I_*` (`.clas.abap` + `.clas.locals_imp.abap`)
   — **this is where FU#3 bites** (see table below). The 13 managed masters
   activate cleanly (no BAPI code); the 13 unmanaged pools must syntax-check
   against your release's DDIC structures.
5. **Projection behavior definitions** `ZC_*.bdef.asbdef`.
6. **Service definitions** `ZUI_*.srvd.srvdsrv` (26).

Checklist:

- [ ] All 123 `ZI_*`/`ZC_*` views active, no red.
- [ ] All 52 behavior definitions active.
- [ ] All 28 behavior pools active (managed first — they're the safe ones).
- [ ] All 26 service definitions active.

---

## FU#3 — Confirm the VERIFY markers (inside FU#2 step 4)

These are the release-specific BAPI/DDIC details that CI cannot check (it
validates block balance, not type names). Each is flagged with a `VERIFY` comment
in the source. Confirm field/structure names against your S/4HANA 2025 stack;
wrong names = activation error on that pool.

| Behavior pool (`backend/.../*.clas.locals_imp.abap`) | Confirm |
|---|---|
| `goods-movement-hu-rap/zbp_i_hu_item` | `gm_code` ('04' transfer / '01' GR) + move type for the box scenario |
| `post-packing-gr-rap/zbp_i_post_packing_gr` | GR `gm_code` '01' / movement type for the post-packing GR |
| `mtos-process-rap/zbp_i_mtos_process` | `BAPI_MATPHYSINV_CREATE_MULT` head/item/docs structure names + head↔item linkage |
| `batch-status-rap/zbp_i_batch_status` | `ZPP_BATCHN` key (`BATCHNO` ± `GJAHR`); `BAPI_BATCH_CHANGE` `MATERIAL` vs `MATERIAL_LONG` width |
| `palletization-rap/zbp_i_palletization` | `BAPI_HU_CREATE` / `BAPI_HU_PACK` parameter names |
| `packing-detail-rap/zbp_i_packing_detail` | `BAPI_HU_CREATE` / `BAPI_HU_PACK` + `BAPI_HU_REPACK_ITM` interface |
| `hu-inbound-rap/zbp_i_hu_inbound` | `BAPI_INB_DELIVERY_CONFIRM_DEC` `bapiibdlvhdrcon` / `bapiibdlvhdrctrlcon` field names |
| `sales-doc-status-rap/zbp_i_sales_doc_status` | contract path (`BAPI_CUSTOMERCONTRACT_CHANGE` alt), "fully delivered" test, `PR00` condition type config |
| `packing-hu-rap/zbp_i_packing_unit` | `BAPI_HU_CREATE` / `BAPI_HU_PACK` parameter names |
| `hu-unpack-rap/zbp_i_hu_unpack` | `BAPI_HU_UNPACK` parameter names + target storage loc |
| `qm-mass-results-rap/zbp_i_qm_inspectionchar` | `bapi2045d4` result-structure field names |
| `dispatch-correction-rap/zbp_i_dispatch_box` | guard: reverse goods movement only if the box is not already invoiced/posted |

- [ ] Every row confirmed or corrected; unmanaged pools all activate.
- [ ] Smoke-test one action per BAPI family in the gateway client / a unit test.

---

## FU#1 — Create + activate the OData V4 service bindings

One **service binding** (type *OData V4 — UI*) per service definition, then
activate it (this publishes the `/sap/opu/odata4/...` service group). Then put
the **published binding/service name** into two places per app:
`manifest.json` `dataSources.mainService.uri` (`REPLACE_WITH_*_SERVICE`) and, for
the apps that invoke a **bound action**, the controller `SERVICE_NS`
(`REPLACE_WITH_SERVICE_NAMESPACE`) = the activated service definition name.

Suggested binding name convention: `<SRVD>_O4`.

| Service def | App(s) | manifest token | Needs `SERVICE_NS`? |
|---|---|---|---|
| `ZUI_HU_GOODS_MOVEMENT` | post-goods-movement-hu | `REPLACE_WITH_HU_GM_SERVICE` | ✅ |
| `ZUI_PACKING` | dyeing-packing | `REPLACE_WITH_PACKING_SERVICE` | ✅ |
| `ZUI_CONTRACT_BATCH` | contract-batch-update | `REPLACE_WITH_CONTRACT_BATCH_SERVICE` | ✅ |
| `ZUI_PALLETIZATION` | palletization | `REPLACE_WITH_PALLETIZATION_SERVICE` | ✅ |
| `ZUI_DISPATCH_CORRECTION` | dispatch-correction | `REPLACE_WITH_DISPATCH_CORRECTION_SERVICE` | ✅ |
| `ZUI_HU_INBOUND` | inbound-delivery-hus | `REPLACE_WITH_HU_INBOUND_SERVICE` | ✅ |
| `ZUI_PACKING_DETAIL` | manage-packing-details | `REPLACE_WITH_PACKING_DETAIL_SERVICE` | ✅ |
| `ZUI_MTOS_PROCESS` | mtos-process | `REPLACE_WITH_MTOS_PROCESS_SERVICE` | ✅ |
| `ZUI_HU_UNPACK` | hu-unpack | `REPLACE_WITH_HU_UNPACK_SERVICE` | ✅ |
| `ZUI_POST_PACK_GR` | post-packing-gr | `REPLACE_WITH_POST_PACK_GR_SERVICE` | ✅ |
| `ZUI_BATCH_STATUS` | batch-status | `REPLACE_WITH_BATCH_STATUS_SERVICE` | ✅ |
| `ZUI_QM_INSPECTIONCHAR` | record-inspection-results-mass | `REPLACE_WITH_QM_MASS_SERVICE` | ❌ (mass saver) |
| `ZUI_SALESDOC_STATUS` | manage-sales-contracts-ext / -orders-ext | `REPLACE_WITH_SALESDOC_STATUS_SERVICE` (×2, in `SERVICE_URL`) | n/a (adaptation) |
| `ZUI_DD_SHADE`, `ZUI_RECIPE`, `ZUI_SCHEDULE`, `ZUI_MERGE`, `ZUI_EXPORT_DETAIL`, `ZUI_CFORM`, `ZUI_JOB`, `ZUI_CHECKED_BY`, `ZUI_TRUCK`, `ZUI_TRANSPORT`, `ZUI_GATEPASS`, `ZUI_PACKING_MATERIAL`, `ZUI_DIGITAL_SIGNATURE` | 13 managed-master apps | per-app token | ❌ (list/object only, no bound action) |

Checklist:

- [ ] 26 service bindings created + activated; service groups published in `/IWFND/V4_ADMIN`.
- [ ] Every `REPLACE_WITH_*_SERVICE` token replaced in the app `manifest.json` files.
- [ ] Every `SERVICE_NS = "REPLACE_WITH_SERVICE_NAMESPACE"` set to the activated
      service definition name (11 freestyle controllers + the 2 sales-doc adaptation
      `SERVICE_URL`s). Note: record-inspection-results-mass binds via its
      `manifest.json` token only (no `SERVICE_NS` constant — it saves through a
      mass saver, not a bound action).
- [ ] `grep -rn "REPLACE_WITH" apps` returns nothing.

---

## FU#4 — ATC clean run + Fiori tile publishing

- [ ] **ATC** — run the *SAP Cloud Ready* / clean-core variant over the `Z*`
      package(s). Target: zero priority-1/2 findings. Expected real items to
      resolve: none should reference released-API misuse (we only consume `I_*`
      released CDS + released BAPIs), but confirm.
- [ ] **DCL note** — no access controls were authored (`@AccessControl.authorizationCheck`
      is `#CHECK` on the views but there are 0 `.dcls`). Before go-live, author a
      DCL per business object or set `#NOT_REQUIRED` with sign-off; ATC will flag
      `#CHECK` without a matching DCL.
- [ ] **Fiori tiles** — for each app, create the target mapping + tile in a
      business catalog, assign to the business role in PFCG. See
      [`PUBLISHING.md`](PUBLISHING.md) and the base-app role mapping in
      [`ACTIVATION.md`](ACTIVATION.md).
- [ ] **Adaptation projects** (manage-sales-contracts-ext / -orders-ext) — fill
      the base-app component id / extension-point ids in the BAS Adaptation Editor
      against the now-live base apps, then deploy.
- [ ] Smoke-test each tile end-to-end in the FLP (`/sap/bc/ui2/flp?sap-client=500`).

---

## Done when

- [ ] All 26 services reachable over OData V4, no `REPLACE_WITH` left in `apps/`.
- [ ] Every VERIFY marker confirmed; all behavior pools active.
- [ ] ATC clean; DCL decision recorded.
- [ ] Every app has a tile under its role and passes a manual smoke test.
