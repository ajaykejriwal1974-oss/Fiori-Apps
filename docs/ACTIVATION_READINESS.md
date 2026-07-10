# Fiori-Apps — Activation Readiness Checklist

> **Purpose:** what is still required before each backend service and its Fiori app
> can be activated and used in a live S/4HANA system. Derived from a full scan of
> `/backend` and `/apps` on branch `claude/fiori-app-extensions-h1nb64`.
>
> **Status legend:** 🟢 wired / fuller · 🟡 partial · ⚠️ skeleton (verify + wire before activating)
>
> **Headline:** the repo ships the **modelling layer** (CDS + RAP behavior + service
> definitions + Fiori Elements annotations). It does **not** create database tables
> (one spec-only exception, `ZDD_SHADE`) and most transactional handlers are
> **skeletons with BAPI calls left as TODO**. Treat every item below as
> *verify against your release before activating.*

---

## 0 · Global pre-requisites (apply to every app)

1. **System baseline** — build/transport on **S/4HANA 2025**. DEV (KSD) is still 1909;
   the only 2025 system today is KSQ. Nothing here can be activated on 1909.
2. **Authorization** — most interface CDS views ship with
   `@AccessControl.authorizationCheck: #NOT_REQUIRED`. Before production, switch the
   consumption views to **`#CHECK`** and add **DCL** (access controls).
3. **OData V4 bindings** — for each service definition (`Z*.srvd`), create and
   **publish the service binding** (`Z*_O4`) in ADT, then activate the ICF node (`SICF`).
4. **FLP content** — build a **Z technical catalog + catalog + tile + target mapping**
   (or Spaces & Pages on 2025) and assign to a **Z business role** (`PFCG`) per app.
5. **Transport** — package all objects and transport **DEV → QA → PROD** once DEV is on 2025.

---

## 1 · Database tables to create

Only **one** new table is introduced anywhere in the repo, and it is **spec-only**
(a Markdown field list, not a DDIC object). Every other app binds to a **legacy
Z-table that already exists** or reads **standard SAP tables** — nothing to create.

| Table | App | State in repo | Action required |
|---|---|---|---|
| `ZDD_SHADE` | shade-master-rap (Shade Master) | **Spec only** — `zdd_shade.table-spec.md` | **Create the transparent table** in ADT/SE11 from the spec (delivery class `A`; key `client` + `shade_code`; admin fields `abp_*`). Prefer a data element `zdd_shade_code` over raw `char10`. |

All master-data apps below reuse **pre-existing** legacy tables — **do not re-create them.**

---

## 2 · Custom / freestyle apps (unmanaged RAP over standard SAP) — wire the BAPIs

These run on **standard SAP tables + BAPIs**; no Z-table. Main gap = **BAPI wiring**
in the behavior handler is best-effort/TODO and must be verified per release.

| Backend | Reads | BAPI(s) to wire / verify | Status | To do before activation |
|---|---|---|---|---|
| batch-status-rap | `MCHA` | `BAPI_BATCH_CHANGE` | ⚠️ skeleton | Wire BAPI in handler; verify batch classification fields |
| contract-batch-rap | `VBAK/VBAP` | `BAPI_SALESDOCUMENT_CHANGE` | ⚠️ skeleton | Not compile-ready; wire + verify field mapping |
| goods-movement-hu-rap | `VEKP/VEPO` | `BAPI_GOODSMVT_CREATE` | ⚠️ skeleton | Verify movement-type/field mapping |
| hu-inbound-rap | `VEKP` | `BAPI_INB_DELIVERY_CONFIRM_DEC` | ⚠️ skeleton | Wire `postInboundGr`; verify |
| hu-unpack-rap | `VEPO/VEKP` | `BAPI_HU_UNPACK` | ⚠️ skeleton | Wire `unpackItems` in handler |
| packing-hu-rap | `VEKP` | `BAPI_HU_CREATE`, `BAPI_HU_PACK` | ⚠️ skeleton | Not compile-ready; wire `createHandlingUnits` |
| packing-detail-rap | `VEKP/VEPO` | `BAPI_HU_PACK`, `BAPI_HU_REPACK_ITM` | ⚠️ skeleton | Wire `packItems`/`repackItems` (BAPI TODO) |
| palletization-rap | `VEKP` | `BAPI_HU_PACK` | ⚠️ skeleton | Wire `packPallet` |
| post-packing-gr-rap | `VEKP/VEPO` | `BAPI_GOODSMVT_CREATE` (✅), `BAPI_HU_PACK` (add) | 🟡 partial | GR wired; add packing step |
| qm-mass-results-rap | `QALS/QAMV/QAPO/QAMR` | `BAPI_INSPCHAR_SETRESULT`, `_CLOSE` | ⚠️ skeleton | Saver wired; verify QM fields/status params |
| mtos-process-rap | `MSKA` | `BAPI_GOODSMVT_CREATE`, `BAPI_MATPHYSINV_*` | 🟡 partial | `convertToMts` wired ✅; `createPhysInvDoc` TODO |
| dispatch-correction-rap | `ZSOL_HUDISPATCH ⋈ ZPP_PACK` | (action wired) | 🟢 fuller | Verify notes, then activate |
| sales-doc-status-rap | `VBAK/VBAP` | `BAPI_SALESDOCUMENT_CHANGE` (✅) | 🟢 fuller | 6 actions wired; verify |

---

## 3 · Master-data Fiori Elements apps (managed RAP) — bind to EXISTING legacy Z-tables

No table to create — the managed BO maps onto a table that **already exists** from the
legacy Z-system. Main gap = **verify value-help / released VH names** and ETag fields.

| Backend | Binds to (existing) | Status | To do before activation |
|---|---|---|---|
| recipe-master-rap | `ZPP_RECEIPE` | 🟢 fuller | Verify 19 fields; no ETag/TIMESTAMPL — add if optimistic locking needed |
| schedule-master-rap | `ZPP_SCHEDULEN` | 🟢 fuller | Verify 23 fields; key `SCHNO`+`GJAHR` |
| job-master-rap | `ZPP_JOBN` | 🟢 fuller | Verify VH names |
| merge-master-rap | `ZPP_MERGE` | 🟢 fuller | Verify VH names |
| packing-material-master-rap | `ZPACK_MAST` | 🟢 fuller | Verify VH names |
| transport-code-master-rap | `ZTRANS` | 🟢 fuller (thin, 3 fields) | Verify key `ZZTRCODE`+`ZZTRCKNO` |
| truck-master-rap | `ZTB_TRUCK_MSTR` | 🟢 fuller (thin, 2 fields) | Verify key `TRUCKNO` |
| cform-master-rap | `ZCFORM1` | 🟢 fuller | Verify released VH names |
| checked-by-master-rap | `ZPP_PCBY` | 🟢 fuller | Verify released VH names |
| digital-signature-master-rap | `ZTDIGI_SIGN` | 🟢 fuller | Verify released VH names |
| export-detail-master-rap | `ZEXP` | 🟢 fuller | Verify released VH names |
| gate-pass-rap | `ZGP_HDR/ZGP_ITEM/ZGP_PART` | 🟢 fuller (composition BO) | Wire number-range + print (TODO) |
| **shade-master-rap** | **`ZDD_SHADE` (NEW)** | 🟢 CDS fuller | **Create the table first** (see §1), then activate |

---

## 4 · Automation / helper / reuse (no UI app)

| Backend | Type | To do before activation |
|---|---|---|
| po-automation | Schedulable ABAP class `ZCL_PO_AUTOMATION` (std `VBRK/VBRP` + `BAPI_PO_CREATE1`) | ⚠️ Wire `BAPI_PO_CREATE1` (TODO); schedule as job |
| obd-automation | Schedulable ABAP class `ZCL_OBD_AUTOMATION` | ⚠️ Delivery-create + GI + status update TODO |
| hu-shared | Read-only base views over `VEKP ⋈ VEPO` | Helper only — consumed by HU apps; no standalone activation |
| minmax-master-rap | Reduced to "reuse standard *Manage Material*" | No build — use standard app |
| bill-of-exchange-std | Routing stub — "use standard FI" | No build — activate standard FI Bill-of-Exchange txns |

---

## 5 · Analytics (CDS analytical queries — no UI5 app, no table)

`/backend/analytics` holds **11 analytical queries + 10 cubes** (read-only) over
existing Z-tables. There is **no deployable app** — the queries surface through
generic SAP analytics tools (Query Browser / Analytical List Page / SAC).

Queries: `ZC_PackedStockQuery`, `ZC_PackingRegisterQuery`, `ZC_WipBatchQuery`,
`ZC_MergeAnalysisQuery`, `ZC_RecipeAnalysisQuery`, `ZC_JobCardQuery`,
`ZC_HuInventoryQuery`, `ZC_PendingContractQuery`, `ZC_ExportRegisterQuery`,
`ZC_DispatchRegisterQuery`, `ZC_GstTaxQuery`.

**To do before activation:**
1. Complete remaining **joins / associations / unit fields** in the cube views.
2. Switch `@AccessControl.authorizationCheck` from `#NOT_REQUIRED` to **`#CHECK`** + add **DCL**.
3. Assign to a **reporting role**; expose via **Query Browser** or an **Analytical List Page** tile.
4. (Note: `ZI_PackedStockCube` is shared by PackedStock + PackingRegister.)

---

## 6 · Suggested activation order

1. **Upgrade DEV (KSD) to S/4HANA 2025** (hard blocker for everything).
2. **Create `ZDD_SHADE`** table (only new persistence).
3. **Master-data apps** (§3) — lowest risk: bind existing tables, verify VH, publish service, build tile.
4. **Analytics** (§5) — read-only; fix auth + wiring, expose via Query Browser.
5. **Custom/freestyle apps** (§2) — wire + unit-test each BAPI action against your release; highest risk.
6. **Automation classes** (§4) — wire BAPIs, schedule as background jobs.
7. Per app: **auth objects → catalog + group + PFCG role → target mapping + tile → activate OData → test → transport.**

---

## 7 · Activation process by app type (how it differs from a standard app)

**Only the final FLP steps are common to all types.** A standard app is *activate-only*;
custom, Fiori Elements, and Z-query all require you to build and register your own
objects first, then converge onto the same tail.

**Common tail (same for all):** publish OData service → activate ICF (`SICF`) →
catalog + tile + target mapping → business role (`PFCG`) → test.

| Step (before the tail) | Standard | Custom (freestyle) | Fiori Elements | Z-query report |
|---|---|---|---|---|
| Build data model (CDS/table) | ❌ SAP ships it | ✅ build CDS/RAP | ✅ build CDS/RAP + annotations | ✅ build CDS query + cube |
| Build/deploy the UI | ❌ shipped | ✅ deploy SAPUI5 BSP app | ⚠️ none — UI generated from service | ❌ no UI at all |
| Register your OData service | ❌ already there | ✅ your `Z…_O4` | ✅ your `Z…_O4` | ⚠️ query exposed, not a txn service |
| Create catalog/tile | ❌ use SAP's | ✅ build Z catalog + tile | ✅ build Z catalog + tile | ⚠️ often no tile — Query Browser / ALP |
| Business role | Assign `SAP_BR_*` | Build/assign `ZBR_*` | Build/assign `ZBR_*` | Reporting role |
| Rapid activation (`STC01` task list) | ✅ available | ❌ manual | ❌ manual | ❌ manual |

- **Standard** → activation only (often via a rapid-activation task list). No build.
- **Custom (freestyle)** → most steps: deploy the UI5 app **and** build your own FLP content + role.
- **Fiori Elements** → same as custom **minus the UI deployment** (the floorplan is generated at runtime from the OData service + annotations).
- **Z-query report** → not an app activation at all: make the CDS query consumable
  (`@Analytics.query`, auth `#CHECK` + DCL) and reach it through a generic analytics
  app (Query Browser / Analytical List Page / SAC) — usually with no tile of its own.

---

_Generated from a static scan of the repository; every BAPI, field, and value-help
reference is best-effort and must be verified against your S/4HANA release and the
original Z program before activation._
