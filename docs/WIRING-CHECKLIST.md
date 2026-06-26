# Wiring checklist — what must be filled before activation on KSQ

The repo is a **clean-core source/spec package**: structurally complete and
CI-validated, but with **intentional placeholders** for every value that only
exists on the live S/4HANA system, and `TODO` markers for the backend BAPI logic.
None of these block **merging to `main`** (they're inert) — they block **running
the artifacts on KSQ**. This is the punch list, by category.

> All work below requires **ADT access to KSQ/KHQ (client 500)** — it cannot be
> done in this repo alone. Sequence: [`ACTIVATION.md`](ACTIVATION.md) →
> [`TRANSPORT-PLAN.md`](TRANSPORT-PLAN.md) → per-app [`GO-LIVE-CHECKLIST.md`](GO-LIVE-CHECKLIST.md).

## 1. OData V4 service bindings  (`REPLACE_WITH_*_SERVICE`, 15 services)
Each RAP service definition needs a **service binding** created + activated in
ADT; then put the binding name in the app's `manifest.json` (and any controller
side-service URL). One per service:

| Service def | Binding to create | Used by |
|---|---|---|
| `ZUI_MTOS_PROCESS` | `ZUI_MTOS_PROCESS_O4` | apps/mtos-process |
| `ZUI_PACKING_DETAIL` | `…_O4` | apps/manage-packing-details |
| `ZUI_PALLETIZATION` | `…_O4` | apps/palletization |
| `ZUI_POST_PACK_GR` | `…_O4` | apps/post-packing-gr |
| `ZUI_HU_UNPACK` / `ZUI_HU_INBOUND` / `ZUI_HU_GOODS_MOVEMENT` | `…_O4` | HU apps |
| `ZUI_BATCH_STATUS` / `ZUI_DISPATCH_CORRECTION` / `ZUI_CONTRACT_BATCH` | `…_O4` | resp. apps |
| `ZUI_SALESDOC_STATUS` | `…_O4` | both sales adaptations (×4 refs) |
| `ZUI_QM…` (mass results) | `…_O4` | record-inspection-results-mass |
| masters (`ZUI_RECIPE`, `ZUI_JOB`, … `ZUI_GATEPASS`, `ZUI_CFORM`) | `…_O4` | FE apps generated from the `.ddlx` |

## 2. Adaptation-project base-app identifiers  (4 adaptations)
The 4 adaptation projects bind to the **standard** app you're extending — these
come from the activated base app on KSQ:

| Placeholder | Source | Count |
|---|---|---|
| `REPLACE_WITH_BASE_APP_COMPONENT_ID` | base app's SAPUI5 component id | 30 |
| `REPLACE_WITH_BASE_APP_BSP_NAME` | base app's BSP/repository name | 4 |
| `REPLACE_WITH_BASE_APP_FIORI_ID` | Fiori Apps Library id | 1 |
| `REPLACE_WITH_OBJECT_PAGE_VIEW_ID` / `…_CONTROLLER_NAME` | base ObjectPage view/controller | 6 |
| `REPLACE_WITH_EXTENSION_POINT_NAME` | base app extension point | 4 |

(Manage Sales Orders F1873, Confirm Production Operation F3069, Manage Outbound
Deliveries F0867A, Manage Sales Contracts.)

## 3. Backend BAPI / logic bodies  (`TODO`, 16 ABAP classes)
The unmanaged action handlers have the read model + framework wired; the **actual
BAPI call** in each is `TODO`:

| Backend | Action(s) → BAPI |
|---|---|
| sales-doc-status-rap (12 TODOs) | close/complete/release/updateRate/closeOrder → `BAPI_SD_SALESDOCUMENT_CHANGE` |
| mtos-process-rap | `BAPI_GOODSMVT_CREATE` (411 E) + `BAPI_MATPHYSINV_CREATE_MULT` |
| packing-detail / packing-hu / palletization / post-packing-gr | `BAPI_HU_PACK` / `_REPACK_ITM` / `_CREATE` (+ GR) |
| hu-unpack / hu-inbound / goods-movement-hu | `BAPI_HU_UNPACK` / `_INB_DELIVERY_CONFIRM_DEC` / `_GOODSMVT_CREATE` |
| batch-status / contract-batch | `BAPI_BATCH_CHANGE` / `BAPI_SD_SALESDOCUMENT_CHANGE` |
| dispatch-correction | `ZSOL_DISPATCH_CORRECTION` update |
| qm-mass-results | QM result-recording API |
| po-automation / obd-automation | Purchase-Order / Outbound-Delivery API |

## 4. Front-end action invocation  (`TODO`, 12 controllers)
The freestyle worklists + the 2 adaptation controllers have the buttons, dialogs
and selection wired; the **OData V4 `oOperation.invoke()`** call is `TODO` (build
the parameter structure, invoke, handle the result message).

## 5. Determinations / framework details
- **Gate Pass number range** — assign `GpNumber` from object `ZGPASS_NUM` in
  `setHeaderDefaults` (1 TODO).
- **Managed-master admin/ETag** — legacy tables have no `TIMESTAMPL` column, so
  ETag is omitted; add a column if optimistic locking is required.

## 6. DDIC prerequisites (mostly none)
- **Masters** bind **existing** legacy tables — nothing to create.
- **Shade Master** (`ZDD_SHADE`) custom table — confirm it exists / create it (it
  is the reference CBO that owns its table).
- `minmax-master-rap`, `bill-of-exchange-std` — **stubs** (reuse standard), no code.

## 7. Reuse (optional, recommended) & verification
- Bind existing `ZSOL_*` OData/CDS and `ZSOL_F4*` value helps where they exist
  ([`REUSE-EXISTING.md`](REUSE-EXISTING.md)) instead of the placeholder reads.
- Resolve the 5 `VERIFY` markers (release-specific table/field/status filters,
  e.g. QM `stat34`, HU `vpobj='01'`, `ZGP_PART` key).
- Switch analytics `@AccessControl.authorizationCheck` from `#NOT_REQUIRED` to
  `#CHECK` + a DCL before production.

## 8. Semantic activation (backend-only, can't be done in CI)
Activate every CDS / behavior / service / class and pass **ATC** on KSQ. The CI
here is **structural** only — it cannot resolve standard types or activate.

---
## Does any of this block the merge?
**No.** Merging to `main` establishes the source-of-truth baseline; the wiring
above happens as follow-up commits/transports against it. Recommended order:
**merge → activate masters first** (least wiring: binding + activation only) →
**adaptations** (base-app ids) → **transactional services** (BAPI bodies) →
**automation/analytics**.
