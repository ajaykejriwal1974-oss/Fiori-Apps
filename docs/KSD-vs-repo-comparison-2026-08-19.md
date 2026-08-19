# Fiori-Apps repo vs. live KSD (client 500) — comparison report

**Date:** 19 Aug 2026
**Repo:** `Fiori-Apps` @ `main` = `29ab372` ("feat(fe): actions on mtos/packing/dispatch FE apps", 12 Aug 2026) — local checkout matches `origin/main`
**System:** KSD `192.168.0.19:8000`, client 500, package `ZKGPL_FIORI` (+ BSPs in `$TMP`), read through the Eclipse ADT MCP bridge

---

## Headline

The repository contains **two different ABAP source trees**, and only one of them is what is actually running on KSD.

| Tree | What it is | State vs. live KSD |
|---|---|---|
| `backend/_abapgit_import/src/` | abapGit mirror of `ZKGPL_FIORI`, last pulled 10 Aug | **227 of 228 readable objects byte-identical to live.** Effectively an accurate mirror. |
| `backend/<feature>-rap/src/` (26 folders) | The hand-authored feature sources | **116 of 160 readable objects differ from live**; 86 of those differ functionally, not just cosmetically. |

So: *KSD is in sync with the mirror folder, and out of sync with the feature folders.* The feature folders are not a stale copy of live — they are a **parallel, partly-newer, partly-poorer design** that has never been fully deployed. Anyone reading `backend/batch-status-rap/src/` to understand what runs in production will be reading the wrong file.

---

## 1. Object inventory

`ZKGPL_FIORI` on KSD holds 493 non-generated TADIR objects (plus 148 generated `STOB`). Comparing names against the repo:

### 1.1 In the repo, absent from KSD (36 objects — all from the feature folders)

**a) The Gate Pass RAP app was never deployed** (6 objects)

`ZI_GATEPASS`, `ZC_GATEPASS`, `ZI_GATEPASS_ITEM`, `ZC_GATEPASS_ITEM`, `ZI_GATEPASS_PART`, `ZC_GATEPASS_PART` (DDLS) + `ZC_GATEPASS`/`ZI_GATEPASS` (BDEF) + `ZC_GATEPASS`/`ZC_GATEPASS_ITEM` (DDLX) + `ZUI_GATEPASS` (SRVD) + `ZBP_I_GATEPASS` (CLAS).
Nothing named `Z*GATEPASS*` of this shape exists anywhere on KSD — only the unrelated `ZI_GATEPASS_REGISTER` / `ZC_GATEPASS_REGISTER` analytics views and the old classic `ZGATEPASS*` reports in `Z001` / `ZSD_DEV`.
Note the repo *also* has a separate, deployed **`ZC_GTPASS` / `ZI_GTPASS`** app. Two gate-pass implementations coexist in git; only `GTPASS` is live.

**b) The `_ITEM` composition entities (13 DDLS)**

`ZD_BATCH_CLOSE_ITEM`, `ZD_BATCH_DELETE_ITEM`, `ZD_CTR_BATCH_ITEM`, `ZD_DISPATCH_CORRECT_ITEM`, `ZD_HU_POST_MVT_ITEM`, `ZD_HU_UNPACK_ITEM`, `ZD_INB_GR_HU`, `ZD_MTO_MTS_ITEM`, `ZD_PACK_CREATE_UNIT`, `ZD_PACK_ITEM`, `ZD_PACK_PALLET_BOX`, `ZD_PHYS_INV_ITEM`, `ZD_POST_PACK_GR_ITEM`, `ZD_REPACK_ITEM`.

These are the child entities of the repo's *typed deep-composition* action parameters. KSD instead runs the **flat delimited-string** variant (`ItemList : abap.char(1333)` carrying `MAT=BATCH=QTY=UNIT;…`). See §3.1 — this is the single biggest functional divergence.

**c) Behaviour-pool classes for 10 master-data apps (CLAS)**

`ZBP_I_CFORM`, `ZBP_I_CHECKED_BY`, `ZBP_I_DD_SHADE`, `ZBP_I_DIGITAL_SIGNATURE`, `ZBP_I_EXPORT_DETAIL`, `ZBP_I_MERGE`, `ZBP_I_PACKING_MATERIAL`, `ZBP_I_TRANSPORT`, `ZBP_I_TRUCK` (+ `ZBP_I_GATEPASS` above).
The corresponding BDEFs *do* exist live, so these apps run **unmanaged-read-only or with a different implementation class** on KSD.

**d) Three orphan analytics/helper views**

`ZC_HU_MONITOR`, `ZC_PENDING_DISPATCH`, `ZI_PACKLATESTYEAR` — referenced by feature-folder sources, absent from KSD.

### 1.2 On KSD, absent from the repo

Only **`SRVB ZI_EXPORT_DETAIL`** — a service binding with no counterpart in either repo tree. Everything else on KSD is represented in `_abapgit_import`.

### 1.3 Activation state

`sap_inactive_objects` returns **0** — nothing on KSD is sitting inactive.

---

## 2. Source-level comparison summary

Objects readable through the bridge (DDLS, DDLX, SRVD, CLAS, PROG). Comparison ignores trailing whitespace and blank lines.

| Comparison | Identical | Whitespace only | Functionally different | Not on KSD |
|---|---:|---:|---:|---:|
| `_abapgit_import` vs live | **227** | 0 | **1** | 0 |
| feature folders vs live | 39 | 5 | **116** (86 substantive + 30 naming-only) | 36 |

Of the 116 feature-folder differences, **30 are pure entity-naming style** — the repo declares CamelCase CDS entity names (`ZC_BatchStatus`, `ZI_JobCardCube`, `ZD_OrderResult`) where KSD uses ALL-CAPS (`ZC_BATCH_STATUS`, `ZI_JOB_CARD`, `ZD_ORDER_RESULT`). Functionally equivalent, but it means the two trees can never be reconciled by a plain text merge.

Naming-only differences: `DDLS ZC_CHECKED_BY, ZD_BATCH_CLOSE_RESULT, ZD_BATCH_DELETE_RESULT, ZD_CONTRACT_ACTION, ZD_CONTRACT_RESULT, ZD_DISPATCH_RESULT, ZD_HU_MVT_RESULT, ZD_HU_UNPACK_RESULT, ZD_INB_GR_RESULT, ZD_MTO_MTS_RESULT, ZD_ORDER_ACTION, ZD_ORDER_RESULT, ZD_PACK_PALLET_RESULT, ZD_PHYS_INV_RESULT, ZD_POST_PACK_GR_RESULT, ZD_REPACK_RESULT, ZI_CHECKED_BY, ZI_DIGITAL_SIGNATURE, ZI_HU_ITEM, ZI_PACKING_MATERIAL, ZI_PACKING_UNIT; DDLX ZC_CHECKED_BY, ZC_DIGITAL_SIGNATURE, ZC_EXPORT_DETAIL, ZC_PACKING_MATERIAL; SRVD ZUI_CHECKED_BY, ZUI_DIGITAL_SIGNATURE, ZUI_EXPORT_DETAIL, ZUI_PACKING_MATERIAL, ZUI_SALES_DOC_STATUS`.

---

## 3. The 86 substantive differences — four recurring themes

### 3.1 Action parameters: typed compositions (repo) vs. flat delimited strings (live) — **repo ahead**

13 mass-action imports. The repo models each as a deep composition; KSD packs the items into one `char(1333)` string.

| Object | Live (KSD) | Repo |
|---|---|---|
| `ZD_PACK` | `ItemList : abap.char(1333)` | `_Item : composition [0..*] of ZD_PackItem` |
| `ZD_REPACK` | `ItemList` string | `_Item` → `ZD_RepackItem` |
| `ZD_PACK_CREATE` | `UnitList` string | `_Unit` → `ZD_Pack_Create_Unit` |
| `ZD_PACK_PALLET` | `BoxHuList` string | `_Item` → `ZD_PackPalletBox` |
| `ZD_POST_PACK_GR` | `HandlingUnitList` string | `_Item` → `ZD_PostPackGrItem` |
| `ZD_HU_POST_MOVEMENT` | `HandlingUnitList` string | `_Item` → `ZD_HU_PostMvtItem` |
| `ZD_HU_UNPACK` | `HuItemList` string | `_Item` → `ZD_HuUnpackItem` |
| `ZD_DISPATCH_CORRECT` | `BoxList` string | `_Item` → `ZD_DispatchCorrectItem` |
| `ZD_CTR_BATCH_UPDATE` | `ItemBatchList` string | `_Item` → `ZD_Ctr_Batch_Item` |
| `ZD_PHYS_INV` | `ItemList` string | `_Item` → `ZD_PhysInvItem` |
| `ZD_MTO_MTS` | flat Material/Plant/SalesOrder/Qty | `_Item` composition (one BAPI call for the whole set) |
| `ZD_BATCH_CLOSE` / `ZD_BATCH_DELETE` | flat Material/Plant/Batch | `_Item` composition (mass close/delete, single commit) |
| `ZD_INB_GR` | `InboundDelivery` only | adds `_Item` → `ZD_InbGrHu` |

This is the "audit batch 4" performance work (`perf: _Item compositions…`, 3 Aug). **It is in git but not on KSD** — the running system still does one round trip per line and parses strings.

### 3.2 UI annotations and value helps — **live ahead** (the biggest category, ~35 objects)

The live `ZC_*` projection views carry the full Fiori UI layer that the feature-folder copies lack: `@UI.lineItem`, `@UI.selectionField`, `@UI.headerInfo`, identification facets, `@Consumption.valueHelpDefinition`, and `@Consumption.filter` interval filters.

Affected: `ZC_BATCH_STATUS`, `ZC_CFORM`, `ZC_CONTRACT_ITEM`, `ZC_DIGITAL_SIGNATURE`, `ZC_DISPATCH_BOX`, `ZC_DISPATCH_REGISTER`, `ZC_EXPORT_DETAIL`, `ZC_EXPORT_REGISTER`, `ZC_HU_INBOUND`, `ZC_HU_INVENTORY`, `ZC_HU_ITEM`, `ZC_HU_UNPACK`, `ZC_JOB`, `ZC_JOB_CARD`, `ZC_MTOS_PROCESS`, `ZC_PACKED_STOCK`, `ZC_PACKING_DETAIL`, `ZC_PACKING_MATERIAL`, `ZC_PACKING_REGISTER`, `ZC_PACKING_UNIT`, `ZC_PALLETIZATION`, `ZC_PENDING_CONTRACT`, `ZC_POST_PACKING_GR`, `ZC_RECIPE`, `ZC_RECIPE_ANALYSIS`, `ZC_SALES_DOC_STATUS`, `ZC_SCHEDULE`, `ZC_WIP_BATCH`.

Same story on the service definitions — live exposes the value-help entities, the repo exposes only the main entity:

| Service | Live also exposes | Repo |
|---|---|---|
| `ZUI_BATCH_STATUS` | `ZI_VH_PLANT`, `I_ProductStdVH`, `ZI_VH_COMPANYCODE`, `I_BatchStdVH` | main entity only |
| `ZUI_MTOS_PROCESS` | `ZI_VH_PLANT`, `I_ProductStdVH`, `I_SalesOrderStdVH`, `ZI_VH_COMPANYCODE` | main entity only |
| `ZUI_HU_UNPACK` | `I_ProductStdVH`, `ZI_VH_PLANT`, `ZI_VH_COMPANYCODE`, `I_BatchStdVH` | main entity only |
| `ZUI_PACKING_DETAIL` | `I_ProductStdVH`, `ZI_VH_PLANT`, `ZI_VH_COMPANYCODE`, `I_BatchStdVH` | main entity only |
| `ZUI_DISPATCH_CORRECTION` | `I_SalesOrderStdVH` | main entity only |
| `ZUI_PACKING` | `ZC_HU_ITEM` | main entity only |

Deploying the feature-folder sources as-is would **strip the dropdowns and filter bars from six live apps**.

Related: several repo views swap the custom value helps for released standard ones (`ZI_VH_PLANT` → `I_PlantStdVH`, `I_Product` → `I_MaterialStdVH`, `ZI_VH_SALESORG` → `I_SalesOrganizationStdVH`) in `ZC_CFORM`, `ZC_JOB`, `ZC_RECIPE`, `ZC_SCHEDULE`, `ZC_DIGITAL_SIGNATURE`, `ZC_PACKING_MATERIAL`. That is a deliberate improvement — but it is not what is running.

### 3.3 Company code / plant derivation — **live ahead** (6 views)

Live joins `T001K` on the plant to derive `CompanyCode`; the repo copies dropped both the join and the fields:

`ZI_BATCH_STATUS`, `ZI_HU_UNPACK`, `ZI_PACKING_DETAIL`, `ZI_MTOS_PROCESS` (also aggregates `NSDM_E_MSKA` live vs. raw `MSKA` in the repo), `ZC_HU_UNPACK`, `ZC_PACKING_DETAIL`.

This is the 10 Aug "Company Code filter + dropdown" rollout — done live and mirrored into `_abapgit_import`, never back-ported into the feature folders.

### 3.4 Typing and semantics annotations — **repo ahead** (~12 views)

The repo replaces live's explicit `cast(… as abap.dec(…))` with proper semantic typing:

- `abap.quan` + `@Semantics.quantity.unitOfMeasure`: `ZI_HU_HEADER_BASE`, `ZI_HU_ITEM_BASE`, `ZI_PENDING_CONTRACT`, `ZI_RECIPE`, `ZI_RECIPE_ANALYSIS`, `ZI_SCHEDULE`, `ZI_WIP_BATCH`, `ZI_HU_INVENTORY`
- `abap.curr` + `@Semantics.amount.currencyCode`: `ZI_SALES_DOC_STATUS`, `ZI_EXPORT_DETAIL`, `ZI_EXPORT_REGISTER`, `ZD_PENDING_RATE`

Also correct, also undeployed.

### 3.5 Individually notable

| Object | Difference |
|---|---|
| `ZCL_OBD_AUTOMATION` | Live implements `validate()` pre-dispatch checks and 621 packing-material goods movement. **Repo replaces both with `TODO` stubs** inside a job-schedulable `run()`. Deploying the repo version would break outbound-delivery automation. |
| `ZCL_PO_AUTOMATION` | Live implements full `BAPI_PO_CREATE1` + PBXX pricing + F2/cancellation filters. **Repo stubs PO creation as `TODO`** but adds VKORG-keyed config, item-level `ZMM_AUTOPO` logging and an `iv_lookback` window. Same risk. |
| `ZC_GST_TAX` / `ZI_GST_TAX` | Completely different data sources. Live reads `VBRK` (billing doc, party, date, NetValue, TaxAmount); repo reads `zsol_gst_det` (plant, vendor, ship-to/bill-to and their states). Not a drift — two different reports under one name. |
| `ZI_TRANSPORT` | Live reads `ZTRCKMSTR`; repo still reads legacy `ZTRANS` and adds a `Description` field. |
| `ZI_DISPATCH_BOX` | Repo joins `ZI_PackLatestYear` (which does not exist on KSD) to pick the latest `GJAHR`; live instead guards `erdat` with `dats_is_valid` and casts `NetWeight`. |
| `ZD_PACK_RESULT` | Repo returns `HandlingUnitsCreated` + `TopHandlingUnit`; live returns a single `HandlingUnit` + `Message`. |
| `ZI_PACKED_STOCK`, `ZC_PACKED_STOCK`, `ZC_MERGE_ANALYSIS`, `ZI_MERGE_ANALYSIS`, `ZC_WIP_BATCH`, `ZI_WIP_BATCH`, `ZC_PACKING_REGISTER` | Repo renames exposed elements (`ProductionOrder`→`Order`, `PackingSize`→`Size`). Breaking change for any consumer bound to the live names. |

---

## 4. The one place KSD is behind git

**`ZCL_DELIVERY_CHALLAN_QUERY`** — the only object where `_abapgit_import` differs from live.

Commit `c32f0f7` ("feat(challan): Company/Plant/Material/Batch filters + value helps", 10 Aug) added to the mirror copy:

- range tables and `WHEN 'COMPANYCODE'/'PLANT'/'MATERIAL'/'BATCH'` filter extraction
- `werks, matnr, mergno` in the `zpp_pack` SELECT, plus a `T001K` lookup for company code
- population of `ls_out-plant/material/batch/companycode`
- the four post-filter `DELETE lt_out WHERE … NOT IN …` blocks

**None of this is on KSD.** Meanwhile the live CDS `ZI_DELIVERY_CHALLAN` *already declares* `CompanyCode`, `Plant`, `Material` and `Batch` with their value-help annotations (verified — the live and mirror CDS are byte-identical).

**Net effect on the running system:** the Delivery Challan app shows Company Code / Plant / Material / Batch filter fields with working dropdowns, but the query class never fills the columns and never applies the filters. Selecting a plant returns everything. This is a live defect with the fix already written and committed.

---

## 5. UI5 apps

### 5.1 The 17 deployable apps — all deployed and current

Every app in `deploy-all.sh` exists as a BSP on KSD in `$TMP`, authored by `FIORI_USER`:

`ZBATCH_STATUS`, `ZCONTRACT_BATCH`, `ZDISPATCH_CORR`, `ZDYEING_PACK`, `ZHU_UNPACK`, `ZINB_DEL_HUS`, `ZPACK_DETAILS`, `ZMTOS_PROCESS`, `ZPALLETIZATION`, `ZPOST_GM_HU`, `ZPOST_PACK_GR`, `ZREC_INSP_MASS`, `ZPLANT_DASH`, `ZBATCH_FE`, `ZMTOS_FE`, `ZPACKING_FE`, `ZDISPATCH_FE`.

BSP last-change dates line up with the repo's own history — 16 apps at **12 Aug 2026**, matching HEAD. `ZDYEING_PACK` sits at **10 Aug**, which is correct: `apps/dyeing-packing` has had no commits since 10 Aug (it was left out of the 11–12 Aug rounds of Excel export, sticky headers, sort dialog and quick-search that the other apps received). **Not a deployment gap — a repo consistency gap.** Worth deciding whether dyeing-packing should get the same UX treatment.

### 5.2 Apps folders with no deploy target (5)

`confirm-production-operation-ext`, `kgpl-viewer`, `manage-outbound-deliveries-ext`, `manage-sales-contracts-ext`, `manage-sales-orders-ext` have no `ui5-deploy.yaml` and no BSP on KSD. Four are standard-app extension projects (expected). **`kgpl-viewer` is not** — it received commits on 11–12 Aug and has nowhere to deploy to.

### 5.3 The 22 BSPs in `ZKGPL_FIORI` have no source in `apps/`

`ZACCGRP_APP`, `ZCFORM_APP`, `ZCHECKBY_APP`, `ZDD_SHADE_APP`, `ZDIGISIGN_APP`, `ZDLVCHALLAN`, `ZEXPORT_APP`, `ZGTPASS_APP`, `ZJOB_APP`, `ZMERGE_APP`, `ZPACKINGUNIT`, `ZPACKING_LIST`, `ZPACKMAT_APP`, `ZPALLETSTOCK`, `ZPURCHASEREG`, `ZRECIPE_APP`, `ZRETURNBOX`, `ZSALESDOC_APP`, `ZSCHEDULE_APP`, `ZTRANSP_APP`, `ZTRUCK_APP`, `ZVFORM_APP` (last changed 19–23 Jul, three on 7 Aug).

These exist in git **only as built artifacts** inside `_abapgit_import` (minified `Component.js`, `manifest.json`, `i18n`) — there is no editable UI5 project for any of them. They were built somewhere else (Business Application Studio / the ADT wizard) and cannot currently be rebuilt from this repository.

---

## 6. Method and limitations

- Live inventory from `TADIR` (`devclass = 'ZKGPL_FIORI'`, `delflag = ''`); BSP state from `O2PAGDIR`.
- Live source pulled object-by-object via ADT `sap_get_source` — 228 objects retrieved successfully.
- **Behaviour definitions could not be read.** The MCP bridge requests `/sap/bc/adt/bopf/bdef/sources/<name>`, which returns HTTP 404 on this system; the correct ADT path is `/sap/bc/adt/bo/behaviordefinitions/<name>/source/main`. All 61 BDEFs in `ZKGPL_FIORI` are confirmed present via `TADIR`, but **their source was not compared** — and the repo shows 169 BDEF-file differences between its own two trees, so this is the largest unexamined surface. Worth a manual check in Eclipse, or a fix to the bridge.
- `SICF` (44), `SMIM` (22), `SUSH` (37), `G4BA` (35), `SRVB` (36), `WDCC` (4) are generated or GUID-named; compared by existence only. Live has 2 more `SUSH` and 1 more `SRVB` than the mirror — expected churn from service-binding activation.
- The comparison used `origin/main` cloned fresh. Local uncommitted working-tree changes on the Mac would not be visible here; the backend file count matches exactly (1463), so any drift would be edits within files.

---

## 7. Suggested next steps

1. **Decide which tree is canonical.** Today `_abapgit_import` describes reality and the feature folders describe an intention. Either promote the feature folders (and deploy them) or fold the good parts into the mirror and retire the duplicate tree. Leaving both is the main risk in this repo.
2. **Ship the Delivery Challan fix** (§4) — smallest, highest-value gap; the live app has four broken filters and the code already exists.
3. **Do not bulk-deploy the feature folders.** `ZCL_OBD_AUTOMATION` and `ZCL_PO_AUTOMATION` would regress to `TODO` stubs, six services would lose their value helps, and 13 `_ITEM` entities would need creating first.
4. **Deploy the `_Item` composition work deliberately** (§3.1) if the mass-action performance improvement is still wanted — it needs the 13 child entities, the BDEFs and the behaviour implementations moved together.
5. **Back-port the live-only work into the feature folders**: company-code derivation (§3.3) and the UI annotation/value-help layer (§3.2), so the two trees stop diverging further.
6. **Resolve the two gate-pass implementations** — `ZC_GTPASS` (live) vs `ZC_GATEPASS` (repo only). One of them is dead code.
7. **Get the 22 `ZKGPL_FIORI` BSPs into the repo as buildable UI5 projects**, or accept that they can only ever be maintained through the ADT/BAS tooling.
8. **Fix the BDEF path in the ADT MCP bridge** so behaviour definitions can be diffed; then re-run this comparison for the 61 BDEFs.
