# FLP tile ↔ repo ↔ live BSP reconciliation

**Date:** 2026-08-20
**Evidence:** `TADIR` (`R3TR WAPA`, client 500, `KSD`) read live over ADT +
the KGPL CUSTOM APPS tile screenshots + the 30 folders under `apps/`.

This replaces the package-membership proxy used on 2026-08-19. `TADIR` is
authoritative: a BSP appears there only if it has actually been deployed,
`$TMP` or not.

---

## Headline

**Nothing is left to deploy.** All 25 deployable repo apps — including the
three built this week — are live in KSD. What is missing is **tiles**, not
deployments.

| | Count |
| --- | ---: |
| Z-namespace BSPs live in KSD | **52** |
| ...that have UI5 source in this repo | 25 |
| ...that have **no source anywhere** | **27** |
| Repo folders that are extensions/harnesses (nothing to deploy) | 5 |
| Tiles in KGPL CUSTOM APPS | ~61 |
| Deployed apps with **no tile** | **3** |

---

## 1. Repo apps — all 25 confirmed live

| App folder | Live BSP | Package | Tile in KGPL CUSTOM APPS |
| --- | --- | --- | --- |
| batch-status | ZBATCH_STATUS | `$TMP` | Batch Status |
| batch-status-fe | ZBATCH_FE | `$TMP` | Batch Status |
| contract-batch-update | ZCONTRACT_BATCH | `$TMP` | Contract Batch Update |
| dispatch-correction | ZDISPATCH_CORR | `$TMP` | Dispatch Correction |
| dispatch-correction-fe | ZDISPATCH_FE | `$TMP` | Dispatch Correction |
| dyeing-packing | ZDYEING_PACK | `$TMP` | Dyeing Packing |
| hu-unpack | ZHU_UNPACK | `$TMP` | HU Unpack |
| inbound-delivery-hus | ZINB_DEL_HUS | `$TMP` | Inbound Delivery |
| **label-master** | **ZLABEL_MASTER** | `$TMP` | ❌ **none** |
| manage-packing-details | ZPACK_DETAILS | `$TMP` | Packing Details |
| mtos-process | ZMTOS_PROCESS | `$TMP` | MTOS Process |
| mtos-process-fe | ZMTOS_FE | `$TMP` | MTOS Process |
| packing-details-fe | ZPACKING_FE | `$TMP` | Packing Details |
| palletization | ZPALLETIZATION | `$TMP` | Palletization |
| plant-dashboard | ZPLANT_DASH | `$TMP` | Plant Dashboard |
| post-goods-movement-hu | ZPOST_GM_HU | `$TMP` | Post Goods Movement |
| post-packing-gr | ZPOST_PACK_GR | `$TMP` | Post Packing & GR |
| **production-confirmation-cancel** | **ZPROD_CONF_CAN** | `$TMP` | ❌ **none** |
| record-inspection-results-mass | ZREC_INSP_MASS | `$TMP` | Record Inspection Results |
| **wip-batch-close** | **ZWIP_BATCH_CLS** | `$TMP` | ❌ **none** |
| zdlvchallan | ZDLVCHALLAN | `ZKGPL_FIORI` | Delivery Challan |
| zpackingunit | ZPACKINGUNIT | `ZKGPL_FIORI` | Packing Units |
| zpalletstock | ZPALLETSTOCK | `ZKGPL_FIORI` | Pallet Stock |
| zpurchasereg | ZPURCHASEREG | `ZKGPL_FIORI` | Purchase Register |
| zreturnbox | ZRETURNBOX | `ZKGPL_FIORI` | Unassign Return Boxes |

**20 of the 25 sit in `$TMP`** and therefore cannot be transported to KSQ.

Five folders have no `ui5-deploy.yaml` because they are not standalone apps —
`confirm-production-operation-ext`, `manage-outbound-deliveries-ext`,
`manage-sales-contracts-ext`, `manage-sales-orders-ext` (adaptation projects
extending standard Fiori apps) and `kgpl-viewer` (local dev harness).

---

## 2. Live BSPs with no source in this repo — 27

### 2a. In `ZKGPL_FIORI`, each with a live tile — 17

| BSP | Tile it serves |
| --- | --- |
| ZDD_SHADE_APP | Shade Master |
| ZRECIPE_APP | Recipe Master |
| ZJOB_APP | Job Master |
| ZSCHEDULE_APP | Schedule Master |
| ZMERGE_APP | Merge Details |
| ZCHECKBY_APP | Checked / Packed By |
| ZPACKMAT_APP | Packing Material Master |
| ZTRANSP_APP | Transport Code |
| ZEXPORT_APP | Export Details |
| ZGTPASS_APP | Gate Pass |
| ZTRUCK_APP | Truck Master |
| ZDIGISIGN_APP | Digital Signature |
| ZCFORM_APP | C-Form |
| ZVFORM_APP | GST Tax |
| ZSALESDOC_APP | Sales Document Status |
| ZPACKING_LIST | Packing List |
| ZACCGRP_APP | Account Grouping |

These 17 are **in production use and unversioned**. A redeploy from any
machine overwrites them with no way back.

### 2b. In other packages, older authorship — 10

| BSP | Package | Author |
| --- | --- | --- |
| ZBARCODE | ZFIORI | ABAP_DEV |
| ZCEODASHBOARD | ZFIORI | ABAP_DEV |
| ZFIORISOL | ZFIORI | ABAP_DEV |
| ZPRDDASHBOARD | ZFIORI | ABAP_DEV |
| ZPROCUREMENT | ZFIORI | ABAP_DEV |
| ZSALESDASHBOARD | ZFIORI | ABAP_DEV |
| Z_FIORIAPP1 | ZFIORI | FIORI_USER |
| ZFIORI2 | ZSOL_DASH | FIORI_USER |
| ZBARCODESCAN | Z001 | FIORI_USER |
| ZBARSCAN | Z001 | FIORI_USER |

None appear in KGPL CUSTOM APPS — they belong to other spaces (dashboards,
barcode scanning) or are legacy. Out of scope for this project, but worth
knowing they exist before anyone reuses a name.

---

## 3. Tiles backed by no custom BSP — ~26

These are SAP GUI transaction tiles, Web Dynpro, or standard Fiori apps.
Nothing to build or version:

Dispatch Register · Packed Stock · Packing Register · WIP Batch ·
Merge Analysis · Recipe Analysis · Job Card · Pending Contract ·
Export Register · HU Inventory · Invoice Allocation · GST Tax Register ·
Credit / Debit Note · Sales Register · TDS Register · E-Invoice & E-Way Bill ·
Job_Work Challan · eDocument Cockpit · Release Sales Order ·
Upload Journal Entries · Gate Pass Register · Customer Register ·
PO Closure Register · MTOS · Packing · Dispatch

> Note: **WIP Batch** is the read-only analytics tile over batch status. It is
> *not* the new `wip-batch-close` app, which needs its own tile.

---

## 4. What is actually outstanding

| # | Item | Type |
| --- | --- | --- |
| 1 | Tile: **Cancel Production Confirmation** → `ZPROD_CONF_CAN` | FLP config |
| 2 | Tile: **WIP Batch Close** → `ZWIP_BATCH_CLS` | FLP config |
| 3 | Tile: **Label Master** → `ZLABEL_MASTER` | FLP config |
| 4 | Tile: **Display Production Order** (`CO03`, standard) | FLP config |
| 5 | Repoint 20 `$TMP` BSPs to `ZKGPL_FIORI` | transportability |
| 6 | Pull the 17 `ZKGPL_FIORI` orphan BSPs into `apps/` | source control |
| 7 | Gap #5 — `ZVLMOVE` HU move handler fix | development |
| 8 | Real DCL roles (`#CHECK` passes silently today) | security |

Items 1–4 are one Basis/FLP session. Items 5–6 are the real risk: 37 of the
52 live BSPs are either untransportable or unversioned.
