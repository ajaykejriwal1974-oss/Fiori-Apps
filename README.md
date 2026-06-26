# Fiori Apps – KEJRIWAL extensions

Clean-core SAP Fiori extensions for the S/4HANA 2025 migration, derived from
`KEJRIWAL_Z_to_Fiori_Mapping.pdf`. Each standard app that needs customization
(Table B of the mapping) gets its own **SAPUI5 Adaptation Project** under
`apps/`, layering custom fields / sections / controller logic on top of the
delivered app **without modifying SAP source**.

## Principle

- **Table A** apps (12) → adopt the standard Fiori app as-is, no development
  (activate OData service + assign business catalog/role + retrain). Nothing to
  build here.
- **Table B** apps (10) → adopt the standard app, then re-add the customization
  the clean-core way: key-user / in-app extensibility, custom CDS, or a released
  BAdI / RAP extension — never a modification.

## Apps in this repo

| App | Fiori ID | Replaces (Z) | Status |
|---|---|---|---|
| [Manage Sales Orders](apps/manage-sales-orders-ext) | F1873 | ZVA01 / ZVA01N, ZSOCLOSE | Scaffolded (UI layer; placeholders to complete on live system) |
| [Confirm Production Operation](apps/confirm-production-operation-ext) | F3069 | ZCO11N / ZCO11A | Scaffolded (UI layer; placeholders to complete on live system) |
| [Manage Outbound Deliveries](apps/manage-outbound-deliveries-ext) | F0867A | ZDEL | Scaffolded (UI layer; challan print via Output Management) |
| [Manage Sales Contracts](apps/manage-sales-contracts-ext) | VA42 / verify | ZCON_CLOSE / ZCON_CLOSE1 / ZCOREL / ZCON02 | Scaffolded (UI layer; status actions call backend) |

> All Table B items are now scaffolded (4 adaptation projects + 4 custom apps +
> 1 RAP business object). Each still needs its live-system placeholders filled
> and its documented backend (CDS / RAP / BAdI / HU config / Output Management).

## Custom Fiori apps (not adaptation projects)

Some Table B items need a *different interaction model* than the standard app
offers, so they're built as standalone custom Fiori apps over a (custom) RAP/OData
service rather than as adaptation projects.

| App | Replaces (Z) | Why custom | Status |
|---|---|---|---|
| [Record Inspection Results (Mass)](apps/record-inspection-results-mass) | ZQA32 (vs F2655) | F2655 records one inspection lot at a time; this does mass / multi-lot entry | UI authored; RAP skeleton in backend/qm-mass-results-rap |
| [Post Goods Movement (HU / Box)](apps/post-goods-movement-hu) | ZBOX_MOVE (vs MIGO) | MIGO is a GUI tx; box/HU-wise movement is a scan-driven flow | UI authored; RAP skeleton in backend/goods-movement-hu-rap |
| [Dyeing Packing](apps/dyeing-packing) | ZPACK01D/02D/03D, ZREPACKD | Textile cone/carton/pallet structure not in standard HU UI | UI authored; RAP skeleton in backend/packing-hu-rap |
| [Contract Batch Update](apps/contract-batch-update) | ZBATCH_CHANGE | Mass batch assignment across contract items | UI authored; RAP skeleton in backend/contract-batch-rap |

## Backend (non-UI) artifacts

| Artifact | Type | Replaces (Z) | Status |
|---|---|---|---|
| [Shade Master](backend/shade-master-rap) | RAP Custom Business Object | ZDD_SHADE | Source authored (table + service binding to create in ADT) |
| [QM Mass Results](backend/qm-mass-results-rap) | Unmanaged RAP service | ZQA32 / `ZQM_MASS_RESULT2` (legacy buffer `ZINSPLOT_QA32`) | Skeleton authored (reads std QM; result API + status filter to complete in ADT) |
| [HU Goods Movement](backend/goods-movement-hu-rap) | Unmanaged RAP service | ZBOX_MOVE (backend) | Skeleton authored (BAPI_GOODSMVT_CREATE + HU read to complete in ADT) |
| [Dyeing Packing](backend/packing-hu-rap) | Unmanaged RAP service | ZPACK / ZREPACKD (backend) | Skeleton authored (BAPI_HU_CREATE/PACK to complete in ADT) |
| [Contract Batch Update](backend/contract-batch-rap) | Unmanaged RAP service | ZBATCH_CHANGE (backend) | Skeleton authored (BAPI_SALESDOCUMENT_CHANGE to complete in ADT) |
| [Recipe Master](backend/recipe-master-rap) | Managed RAP master (Route 7) | ZRECP01/02/03 | **Refit to real table `ZPP_RECEIPE`** (19 fields, 5-part key) |
| [Job Master](backend/job-master-rap) | Managed RAP master (Route 7) | ZJOB01/02/03(N) | **Refit to real table `ZPP_JOBN`** (key JOBNO) |
| [Truck Master](backend/truck-master-rap) | Managed RAP master (Route 7) | ZTRUCK | **Refit to real table `ZTB_TRUCK_MSTR`** (key TRUCKNO) |
| [Schedule Master](backend/schedule-master-rap) | Managed RAP master (Route 7) | ZSCH01/02/03(N) | **Refit to real table `ZPP_SCHEDULEN`** (keys SCHNO/GJAHR) |
| [Transport Code](backend/transport-code-master-rap) | Managed RAP master (Route 7) | ZTRANS | **Refit to real table `ZTRANS`** (keys ZZTRCODE/ZZTRCKNO) |
| [~~Min/Max Levels~~ → reuse standard MRP](backend/minmax-master-rap) | Stub (de-scoped) | ZMINMAX | **Reuse standard** — min/max on `MARC`, no custom table |
| [Merge Details](backend/merge-master-rap) | Managed RAP master (Route 7) | ZMERGE | **Refit to real table `ZPP_MERGE`** (keys AURNR/GRADE/ENDUSE) |
| [Checked/Packed By](backend/checked-by-master-rap) | Managed RAP master (Route 7) | ZPCBY | **Refit to real table `ZPP_PCBY`** (keys SR_NO/PC) |
| [Packing Material Master](backend/packing-material-master-rap) | Managed RAP master (Route 7) | ZPACK_MAST | **Refit to real table `ZPACK_MAST`** (keys PTYPE/ARBPL/MATNR) |
| [Export Details](backend/export-detail-master-rap) | Managed RAP master (Route 7) | ZMBR2 | **Refit to real table `ZEXP`** (keys VBELN/KSCHL) |
| [Digital Signature](backend/digital-signature-master-rap) | Managed RAP master (Route 7) | ZDIGI | **Refit to real table `ZTDIGI_SIGN`** (key BUKRS) |
| [HU Unpack](backend/hu-unpack-rap) | Unmanaged RAP service (Route 7) | ZHUPK | Skeleton (BAPI_HU_UNPACK to wire) |
| [MTO→MTS Transfer](backend/mto-mts-transfer-rap) | Unmanaged RAP service (Route 7) | ZMTOS | Skeleton (BAPI_GOODSMVT_CREATE to wire) |
| [Palletization](backend/palletization-rap) | Unmanaged RAP service (Route 7) | ZPALLET / ZPAL_BOX / ZSOL_ASRS | Skeleton (BAPI_HU_PACK to wire) |
| [Batch Status](backend/batch-status-rap) | Unmanaged RAP service (Route 7) | ZBATCHD / ZBATCH_CLS | Skeleton (BAPI_BATCH_CHANGE to wire) |
| [Packing Details](backend/packing-detail-rap) | Unmanaged RAP service (Route 7) | ZPACK01/02/03(+N), ZREPACK | Skeleton (BAPI_HU_PACK / BAPI_HU_REPACK_ITM to wire) |
| [Post Packing & GR](backend/post-packing-gr-rap) | Unmanaged RAP service (Route 7) | ZPOST01 | Skeleton (BAPI_HU_PACK + BAPI_GOODSMVT_CREATE to wire) |
| [Inbound Delivery HUs](backend/hu-inbound-rap) | Unmanaged RAP service (Route 7) | ZHUINB | Skeleton (BAPI_INB_DELIVERY_CONFIRM_DEC to wire) |
| [HU Physical Inventory](backend/hu-phys-inventory-rap) | Unmanaged RAP service (Route 7) | ZHUINV | Skeleton (BAPI_MATPHYSINV_CREATE_MULT to wire) |

The shade master has no standard SAP equivalent, so it's a RAP business object
(not an adaptation project). It also provides the value-help source for the shade
fields in F1873 and F3069.

## Layout

```
apps/
  manage-sales-orders-ext/      # F1873 adaptation project
    webapp/
      manifest.appdescr_variant # app-variant descriptor
      changes/
        fragments/              # custom XML UI sections
        coding/                 # controller extensions
        manifest/               # page-configuration / column changes
        annotations/            # (optional) annotation changes
      i18n/
    ui5.yaml
    package.json
```

Each project's own README lists the `REPLACE_WITH_*` placeholders that must be
filled from the live system and the backend (CDS / RAP / BAdI) prerequisites.

## Docs

- [`docs/EXTENSIBILITY.md`](docs/EXTENSIBILITY.md) — SAP clean-core extensibility
  tiers; per-app guidance on what to build as tier-1 key-user vs. tier-2
  adaptation project vs. backend.
- [`docs/PUBLISHING.md`](docs/PUBLISHING.md) — deploy to the Front-End Server and
  publish/launch each app as its own Fiori Launchpad tile (on-premise).
- [`docs/ACTIVATION.md`](docs/ACTIVATION.md) — how the Basis Fiori activation
  runbook (KSQ/KHQ, client 500) and this repo fit together: base-app activation
  → extension deploy order, and the base app → business role → repo artifact map.
- [`docs/GO-LIVE-CHECKLIST.md`](docs/GO-LIVE-CHECKLIST.md) — per-app checklist:
  placeholder values to collect, backend prerequisites, deploy / publish / verify
  steps, and a suggested execution sequence.
- [`docs/TRANSPORT-PLAN.md`](docs/TRANSPORT-PLAN.md) — package hierarchy and
  transport-request grouping/sequence to move the objects DEV → KSQ → PROD on the
  embedded FES.
- [`docs/CLASSIFICATION.md`](docs/CLASSIFICATION.md) — **authoritative** routing of
  **all 285 tcodes** from the `classification` column (CUS / EXT / STD / BI / PRT /
  UPL), plus how each repo build maps to the CUS/EXT rows. Supersedes ROUTE7-PLAN.
- [`docs/REUSE-EXISTING.md`](docs/REUSE-EXISTING.md) — bind/consume the **existing**
  61 OData services + 96 CDS (`ZSOL_*`, `ZSOL_F4*`) and existing repo apps instead
  of rebuilding; which masters reuse which legacy tables.
- [`docs/ROUTE7-PLAN.md`](docs/ROUTE7-PLAN.md) — earlier routing of the Route 7
  ("keep custom / review") Z-codes (superseded by CLASSIFICATION.md); now carries
  the corrected master→real-table mapping.
