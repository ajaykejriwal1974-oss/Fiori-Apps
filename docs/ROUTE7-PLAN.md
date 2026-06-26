# Route 7 ("Keep custom / review", 68) — build routing

From `KEJRIWAL_Zportfolio_Fiori2025.pdf` §8. These have **no obvious standard
match**. The portfolio doc itself says each must be confirmed by **program code
review + Fiori Apps Reference Library** before committing build effort, so the
routes below are recommendations, not a final build list.

> Key idea: Route 7 is **not 68 apps**. Create/Change/Display variants of one
> master collapse into **one** Fiori Elements app; several items are really
> reports, config, or DRC. We build only the genuine custom transactional objects
> with no standard equivalent — that is the **custom masters** below.

## ✅ Built — managed-RAP custom masters (Shade-Master pattern)
Each is a `backend/<name>-master-rap/` managed RAP BO; the Fiori Elements
"Manage …" app is generated from the service binding via the `.ddlx` (no
hand-written UI). Field lists are best-effort — **VERIFY against the Z program**.

| Master | Replaces (Z) | Folder |
|---|---|---|
| Dyeing Recipe Master (links to Shade Master) | ZRECP01/02/03 | `backend/recipe-master-rap` |
| Job Master | ZJOB01/01N/02/02N/03/03N | `backend/job-master-rap` |
| Truck Master | ZTRUCK | `backend/truck-master-rap` |
| Schedule Master | ZSCH01/01N/02/02N/03/03N | `backend/schedule-master-rap` |
| Transport Code | ZTRANS | `backend/transport-code-master-rap` |
| Min/Max Levels (composite key material+plant) | ZMINMAX | `backend/minmax-master-rap` |
| Merge Details | ZMERGE | `backend/merge-master-rap` |
| Checked / Packed By | ZPCBY | `backend/checked-by-master-rap` |
| Packing Material Master | ZPACK_MAST | `backend/packing-material-master-rap` |
| Export Details (assess vs std foreign trade) | ZMBR2 | `backend/export-detail-master-rap` |
| Digital Signature (confirm not Basis security) | ZDIGI | `backend/digital-signature-master-rap` |

> That is **every Route 7 item that is a genuine custom master** with a derivable
> field set.

## ✅ Built — transactional action services (unmanaged RAP)
The distinct *transactional* Route 7 items (not masters) — a read model + static
action(s) over standard SAP, BAPI marked `TODO` (same pattern as
`backend/goods-movement-hu-rap`):

| Service | Replaces (Z) | Action → BAPI | Folder |
|---|---|---|---|
| HU Unpack | ZHUPK | `unpackItems` → BAPI_HU_UNPACK | `backend/hu-unpack-rap` |
| MTO→MTS Transfer | ZMTOS | `convertToMts` → BAPI_GOODSMVT_CREATE | `backend/mto-mts-transfer-rap` |
| Palletization | ZPALLET / ZPALLET1 / ZPAL_BOX / ZSOL_ASRS | `packPallet` → BAPI_HU_PACK | `backend/palletization-rap` |
| Batch Status | ZBATCHD / ZBATCH_CLS | `closeBatch` / `deleteBatch` → BAPI_BATCH_CHANGE | `backend/batch-status-rap` |

## 🔁 Reuse / extend an app already in this repo (don't build new)
| Z | Route to |
|---|---|
| ZPACK01/01N/02/02N/03, ZREPACK | the [dyeing-packing](../apps/dyeing-packing) app / `backend/packing-hu-rap` (non-dyeing variant = config, not a new app) |
| ZHUINB, ZPOST01 | the [post-goods-movement-hu](../apps/post-goods-movement-hu) pattern / `backend/goods-movement-hu-rap` |
| ZDELC | the F0867A [delivery challan](../apps/manage-outbound-deliveries-ext) (Output Management) |
| ZINSPLOT, ZQAR | QM — extend [record-inspection-results-mass](../apps/record-inspection-results-mass); ZINSPLOT may map to standard Create Inspection Lot |

## 📊 Report → analytics / Metabase (not a transactional app)
`ZMC46` (slow-moving stock), `ZWIP` (order status), `ZPC01` (std vs actual),
`ZBANK` (bank balance). Route to the analytical layer (Route 3), not a custom app.

## ⚙️ Config / assess vs standard first (likely NOT custom)
| Z | Assess against |
|---|---|
| ZZFBL2N | **likely standard** — Manage Supplier Line Items (move to Route 1) |
| ZSOL_AUTOPAY | standard Automatic Payment (F110 / Manage Automatic Payments) |
| ZHUINV | standard Physical Inventory |
| ZBOE | standard Bill of Exchange management |
| ZSOL_ACCGRP | configuration (account grouping), not an app |
| ZGISLIP | GR slip → Output Management (Route 5) |
| ZPDF | spool→PDF utility → platform/automation, not a tile |

## 🚫 Excluded per your instruction — DRC (Document & Reporting Compliance)
The E-Invoice / E-Way Bill cockpit is **standard SAP DRC**, not a custom rebuild:
`ZEINV`, `ZEINV_CANC`, `ZEINV_CO_CODE`, `ZEINV_DOCTYP`, `ZEINV_EWAY_BY_IRN`,
`ZEINV_EXT`, `ZEINV_LOGIN`, `ZEINV_SETUP`, `ZEINV_STATE_CODE`, `ZEINV_UOM`,
`ZEINV_UPDATE`, `ZEINV_UPGRADE`, `ZEWAY_CANC`, `ZEXN` (custom invoice numbering).
→ Replace with **standard DRC for India**; do not build.

## How to add another master
Copy any `backend/*-master-rap/` folder, rename objects (`ZI_*` / `ZC_*` /
`zbp_i_*` / `ZUI_*` / table), adjust the field list to the Z program, and add the
DB table + OData V4 service binding in ADT. The Fiori Elements app comes from the
`.ddlx` metadata extension.
