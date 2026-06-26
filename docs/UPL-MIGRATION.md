# UPL layer — 28 upload/automation programs → APIs / Migration Cockpit (→ ~12)

The **28 `UPL` tcodes** are **bulk loaders** and **robotic posters** — they push
data into SAP, they are not interactive apps. None becomes a Fiori tile. They
re-platform onto three clean-core mechanisms, and several families collapse.

| Target mechanism | Use for |
|---|---|
| **SAP Migration Cockpit** (`LTMC`/`LTMOM`) | one-time / cutover loads (masters, open items) |
| **Public APIs** (OData / SOAP, SAP API Hub) | recurring create/post automation |
| **Standard process / event / job** | replace robotic BDC replays |

> **Retire every BDC program.** `ZBDC_*` / `ZCBDC_*` / `ZRPT_BDC_*` replay
> recorded GUI screens — they break on any standard screen change and are the
> opposite of clean core. Each becomes a proper **API call** or a Migration
> Cockpit object.

## A. PO-creation automation — 9 → 1  ⭐ biggest win
All over `ZMM_AUTOPO` / `ZSOL_AUPO`, one program per plant (5000/6000/7000/8000)
plus "new" variants: `ZAUTOPO`, `ZAUTOPO8`, `ZAUTOPOG`, `ZAUTOPOJ`, `ZAUTOPOM`,
`ZAUTOPOM1`, `ZAUTOPON`, `ZAUTOPOS` (programs `ZPRG_PO_CREATE*`).

→ **one** PO-automation interface with **plant as a parameter**, calling the
**Purchase Order API** (`API_PURCHASEORDER_PROCESS_SRV` / `BAPI_PO_CREATE1`) off
the `ZMM_AUTOPO` driver table. **8 retired.**

## B. FI document posting (F-02) — 4 → 1
`ZF02` (`BAPI_ACC_DOCUMENT_POST`), `ZSAL_POST` (`ZFI_BAPI_F_02`), `ZFIEX`
(BDC F-02), `ZFIVT` (BDC F-02 vendor).

→ **one** journal-posting service on the **Journal Entry API**
(`API_JOURNALENTRY_SRV` / *Post General Journal Entries*). **The two BDC posters
retire**; the two BAPI ones merge. **3 retired.**

## C. FI open-item upload — 3 → 1
`ZFICOI` (customer, BDC), `ZFIGOI` (G/L), `ZFIOP` (vendor) — all open-item loads.

→ **Migration Cockpit** FI open-item objects (one each for customer / vendor /
G/L), driven from **one** load template. **2 retired** (one object, three sheets).

## D. Sales OBD automation — 2 → 1
`ZSDOBD`, `ZSDOBDN` (`ZSD_OBD_AUTOMATION(_NEW)`) — outbound-delivery automation
over `ZSOL_HUDISPATCH` / `ZPP_PACK` / delivery.

→ **one** OBD-automation service on the **Outbound Delivery API**
(`API_OUTBOUND_DELIVERY_SRV` + goods-issue), reusing the dispatch tables. **1 retired.**

## E. One-off master / data uploads → Migration Cockpit (one object each)
| Z | Program | Migration Cockpit object / API |
|---|---|---|
| `ZABMA` | ZFI_ABMA_BAPI_ASSET_UPLOAD | **Fixed asset** (incl. balances) |
| `ZBANK_VEND` | ZSOL_VEND_BANK_CHANG | **Business Partner** bank details (BP API) |
| `ZVK11` | ZPRG_BDC_VK11 (BDC) | **Pricing condition records** (condition API) — retire BDC |
| `ZIA01` | ZEQUIPMENT_TASK_UPLOAD | **Equipment task list** (PM object) |
| `ZWMTO_UPLD` | ZWM_TRANSFER_ORDER_UPLOAD | **Warehouse transfer order** (WM/EWM API) |

## F. Recurring single-transaction automation → API
| Z | Program | Replace with |
|---|---|---|
| `ZV2` | ZCBDC_SD_VA02_001 (BDC) | **Sales Order API** change (`API_SALES_ORDER_SRV`) — retire BDC |
| `ZSCANU` | ZRPT_SALES_UPLOAD | Packing-scan upload → the packing apps' **OData** (reuse `backend/packing-detail-rap`) |
| `ZFIBRC` | ZFI_BANK_CLEAR | **Electronic Bank Statement / Bank Reconciliation** (standard `FF.5`/`FEBAN`) |

## G. Already covered / excluded (3)
| Z | Status |
|---|---|
| `ZHU_UNPACK` (`ZSOL_BAPI_HU_UNPACK`) | the BAPI behind **`backend/hu-unpack-rap`** (built) |
| `ZVLMOVE` (`ZSOL_VLMOVE_BAPI`) | goods-movement/delivery move — covered by **`backend/goods-movement-hu-rap`** |
| `ZEINV_UPLOAD` | **DRC** (excluded — e-invoice IRN upload) |

## Net result
| | Programs |
|---|---:|
| Start | **28** |
| PO automation (A) | −8 |
| FI posting (B) | −3 |
| FI open items (C) | −2 |
| OBD automation (D) | −1 |
| Already covered / excluded (G) | −3 |
| **Target** | **≈ 11** |

**28 → ~11**: 1 PO-automation API + 1 FI-posting API + 1 OBD-automation API + 1
FI open-item migration object + 5 single Migration-Cockpit/API loads (E) +
2 recurring APIs (F, `ZFIBRC` → standard). **All BDC retired.**

## Method
1. **Cutover vs recurring** — one-time loads → Migration Cockpit; ongoing
   automation → an API + scheduled job. Never re-record BDC.
2. **Consolidate** — the `ZAUTOPO*` plant copies and F-02 BDC clones are identical
   bar a parameter; merge before migrating.
3. **Reuse** — point loaders at the **public APIs** (SAP API Hub) and the OData
   services already built here; don't write new posting logic.
4. **Retire** — remove the Z program after the load/parallel run.
