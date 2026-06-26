# Route 7 ("Keep custom / review", 68) — build routing

> ⚠️ **Superseded by [`CLASSIFICATION.md`](CLASSIFICATION.md).** That doc routes
> **all 285 tcodes** from the authoritative `classification` column
> (CUS/EXT/STD/BI/PRT/UPL). The masters below have also been **refit to their
> real Z-tables** from the field dictionary — see the corrected table list.
> For binding to existing services instead of rebuilding, see
> [`REUSE-EXISTING.md`](REUSE-EXISTING.md).

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

Field lists are now **refit to the real Z-tables** (field dictionary) — keys and
all columns mirror the legacy table. Each maps the **existing** table (no new
persistence).

| Master | Replaces (Z) | Real table | Keys | Folder |
|---|---|---|---|---|
| Dyeing Recipe Master (links to Shade) | ZRECP01/02/03 | `ZPP_RECEIPE` | WERKS, GREY_CODE, DYE_CODE, SHDCD, POSNR | `backend/recipe-master-rap` |
| Job Master | ZJOB01/02/03(N) | `ZPP_JOBN` | JOBNO | `backend/job-master-rap` |
| Truck Master | ZTRUCK | `ZTB_TRUCK_MSTR` | TRUCKNO | `backend/truck-master-rap` |
| Schedule Master | ZSCH01/02/03(N) | `ZPP_SCHEDULEN` | SCHNO, GJAHR | `backend/schedule-master-rap` |
| Transport Code | ZTRANS | `ZTRANS` | ZZTRCODE, ZZTRCKNO | `backend/transport-code-master-rap` |
| Merge Details | ZMERGE | `ZPP_MERGE` | AURNR, GRADE, ENDUSE | `backend/merge-master-rap` |
| Checked / Packed By | ZPCBY | `ZPP_PCBY` | SR_NO, PC | `backend/checked-by-master-rap` |
| Packing Material Master | ZPACK_MAST | `ZPACK_MAST` | PTYPE, ARBPL, MATNR | `backend/packing-material-master-rap` |
| Export Details | ZMBR2 | `ZEXP` | VBELN, KSCHL | `backend/export-detail-master-rap` |
| Digital Signature | ZDIGI | `ZTDIGI_SIGN` | BUKRS | `backend/digital-signature-master-rap` |
| ~~Min/Max Levels~~ → **reuse standard MRP** | ZMINMAX | `MARC` (std) | — | `backend/minmax-master-rap` (stub) |

> **Correction from the field dictionary:** `ZTRUCK` *does* have a real table
> (`ZTB_TRUCK_MSTR`); `ZMINMAX` does **not** — it maintains standard MRP min/max
> on `MARC`, so it was de-scoped to a reuse stub (no custom table). Number range
> for Schedule lives in `ZPP_SHNUM`; the FG↔RM merge cross-ref in `ZTB_MERGE_MST`.

## ✅ Built — transactional action services (unmanaged RAP)
The distinct *transactional* Route 7 items (not masters) — a read model + static
action(s) over standard SAP, BAPI marked `TODO` (same pattern as
`backend/goods-movement-hu-rap`):

| Service | Replaces (Z) | Action → BAPI | Folder |
|---|---|---|---|
| HU Unpack | ZHUPK | `unpackItems` → BAPI_HU_UNPACK | `backend/hu-unpack-rap` |
| MTO→MTS Transfer | ZMTOS | `convertToMts` → BAPI_GOODSMVT_CREATE | `backend/mtos-process-rap` |
| Palletization | ZPALLET / ZPALLET1 / ZPAL_BOX / ZSOL_ASRS | `packPallet` → BAPI_HU_PACK | `backend/palletization-rap` |
| Batch Status | ZBATCHD / ZBATCH_CLS | `closeBatch` / `deleteBatch` → BAPI_BATCH_CHANGE | `backend/batch-status-rap` |
| Packing Details | ZPACK01/02/03(+N), ZREPACK | `packItems` → BAPI_HU_PACK, `repackItems` → BAPI_HU_REPACK_ITM | `backend/packing-detail-rap` |
| Post Packing & GR | ZPOST01 | `postPackingAndGr` → BAPI_HU_PACK + BAPI_GOODSMVT_CREATE | `backend/post-packing-gr-rap` |
| Inbound Delivery HUs | ZHUINB | `postInboundGr` → BAPI_INB_DELIVERY_CONFIRM_DEC | `backend/hu-inbound-rap` |
| HU Physical Inventory | ZHUINV | `createPhysInvDoc` → BAPI_MATPHYSINV_CREATE_MULT | `backend/mtos-process-rap` |

> The full "Packing / HU / pallet" family is now built (8 services). `ZHUINV`
> moved here from "assess vs standard" at your request — still **assess standard
> Physical Inventory first**.

## 🔁 Reuse / extend an app already in this repo (don't build new)
| Z | Route to |
|---|---|
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
