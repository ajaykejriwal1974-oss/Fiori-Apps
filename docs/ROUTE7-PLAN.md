# Route 7 ("Keep custom / review", 68) — build routing

From `KEJRIWAL_Zportfolio_Fiori2025.pdf` §8. These have **no obvious standard
match**. The portfolio doc itself says each must be confirmed by **program code
review + Fiori Apps Reference Library** before committing build effort, so the
routes below are recommendations, not a final build list.

> Key idea: Route 7 is **not 68 apps**. Create/Change/Display variants of one
> master collapse into **one** Fiori Elements app; several items are really
> reports, config, or DRC. Build only what is genuinely a custom transactional
> object with no standard equivalent.

## ✅ Built now — managed-RAP custom masters (Shade-Master pattern)
Each is a `backend/<name>-master-rap/` managed RAP BO; the Fiori Elements
"Manage …" app is generated from the service binding via the `.ddlx`.

| Master | Replaces (Z) | Folder |
|---|---|---|
| Dyeing Recipe Master | ZRECP01 / ZRECP02 / ZRECP03 | `backend/recipe-master-rap` |
| Job Master | ZJOB01/01N/02/02N/03/03N | `backend/job-master-rap` |
| Truck Master | ZTRUCK | `backend/truck-master-rap` |

## 🔨 Build next — same managed-RAP master pattern
Straight repeats of the pattern above (one app per master, C/U/D in one):

| Master | Replaces (Z) | Notes |
|---|---|---|
| Schedule Master | ZSCH01/01N/02/02N/03/03N | production/dispatch schedule |
| Transport Code | ZTRANS | small master |
| Min / Max Levels | ZMINMAX | material min/max (key = material+plant) |
| Merge Details | ZMERGE | |
| Checked / Packed By | ZPCBY | operator master |
| Packing Material Master | ZPACK_MAST | |
| Export Details | ZMBR2 | assess vs standard foreign-trade first |
| Digital Signature | ZDIGI | master/config — confirm not a Basis/security setting |

## 🔁 Reuse / extend an app already in this repo (don't build new)
| Z | Route to |
|---|---|
| ZPACK01/01N/02/02N/03, ZREPACK | the [dyeing-packing](../apps/dyeing-packing) app / `backend/packing-hu-rap` (non-dyeing variant = config, not a new app) |
| ZPALLET, ZPALLET1, ZPAL_BOX, ZSOL_ASRS | same packing / HU app (pallet level) |
| ZHUINB, ZHUPK, ZPOST01, ZMTOS | the [post-goods-movement-hu](../apps/post-goods-movement-hu) pattern / `backend/goods-movement-hu-rap` |
| ZDELC | the F0867A [delivery challan](../apps/manage-outbound-deliveries-ext) (Output Management) |
| ZINSPLOT, ZQAR | QM — extend [record-inspection-results-mass](../apps/record-inspection-results-mass) or a small RAP action |
| ZBATCHD, ZBATCH_CLS | batch close/delete = custom **actions** on Manage Batches (F2462), not a new master |

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

## How to add the next master
Copy any `backend/*-master-rap/` folder, rename objects (`ZI_*` / `ZC_*` /
`zbp_i_*` / `ZUI_*` / table), adjust the field list to the Z program, and add the
DB table + OData V4 service binding in ADT. The generated Fiori Elements app comes
from the `.ddlx` metadata extension — no hand-written UI.
