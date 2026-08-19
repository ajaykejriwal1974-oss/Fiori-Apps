# Fiori coverage vs the plant runbook — verified

**Date:** 2026-08-19
**Sources:** the 28-page scanned runbook (`DocScanner 18 Aug 2026`), the live
Fiori launchpad spaces at `122.179.133.205:5200` (client 500), and this repo.

The runbook is a two-user walkthrough of the dyeing plant (2002):

| User | Role in the scan |
| --- | --- |
| `KID_PP2` / `KID_OM2` | production execution + packing, dyeing department |
| `KID_SD2` | dispatch, packing list, billing |

Every transaction it names is mapped below to the tile that replaces it. The
handwritten annotations in the margin (`OK`, `Needed`, `Not available`,
`Both these T-codes are locked`) are the plant's own verdicts and are quoted.

---

## 1. Production execution — order setup (steps 1–4)

| Scan step | Transaction | Fiori tile | Space | Status |
| --- | --- | --- | --- | --- |
| 1st step | `CA03` Display Routing | Display Routing | Production → Work Centers & Routing | ✅ |
| 2nd step | `MM02` Material change (MRP 3, production versions) | Manage Product Master Data | Inventory & Goods Movement → Master Data | ✅ |
| 3rd step | `CS01`/`CS03` BOM | Create Bill of Material | Production → Master Data | ✅ |
| Last step | `CO03` Production Order display (header, control, operations, components) | — | — | ⚠️ **no tile** |

`CO03` is the only step-4 item with no tile. This is **not development** —
SAP ships *Display Production Order*; it just has to be added to the Production
space. Raise it with the Basis/FLP request in
`BASIS-REQUEST-ZREPRINT-ZPACK02D.md`.

## 2. Production execution — dyeing operations

| Transaction | What it does | Fiori tile | Status |
| --- | --- | --- | --- |
| `ZBATCH01N` | Create Batch Master | Manage Batches / WIP Batch | ✅ |
| `ZJOB01N` | Create Job Master (job card) | Job Master | ✅ |
| `ZCO11A` | Dyeing production entry | Confirm Production Operation | ✅ record side |
| `ZCO11A` | *cancel* a production entry | — | ❌ scan: **"Cancelled option – Not available"** |
| `CO13` | Cancel confirmation of production order | — | ❌ scan: **"Correction option – Not available"** |
| `ZJOBREPTN` | Job Card Master Report (dyeing / winding) | Job Card | ✅ |
| `zbatch_cls` | WIP batch **close** for plant 2002 | WIP Batch (read-only analytics) | ❌ scan: **"Needed"** |

Two real gaps here, both now built (see §6).

The `zbatch_cls` note is worth quoting in full, because it explains the
dependency between the two:

> Two job cards in production. After clearing production in `zbatch_cls`,
> to cancel or deduct, **the Batch Master must be open**.

So cancelling a confirmation and reopening a WIP batch are one workflow: the
batch has to be reopened before the confirmation can be reversed. The WIP Batch
tile shows batches and their `Closed` flag but cannot change it.

## 3. Packing — dyeing department (user `KID_OM2`)

| # in scan | Transaction | What it does | Fiori tile | Status |
| --- | --- | --- | --- | --- |
| 2 | `ZPACK01D` | Create packing details | Dyeing Packing | ✅ *(scan: OK)* |
| 3 | `ZLABEL` | Maintain Label Master | — | ❌ *(scan: OK — i.e. still used in GUI)* |
| 4 | `ZPOST01` | Posting / packing & GR | Post Packing & GR | ✅ *(scan: OK)* |
| 5 | `ZPRP` | Production report (packed / posted / repack) | Packing Register | ✅ *(scan: OK)* |
| 6 | `ZREPACK` | Repack: packing details, G/R packing | Packing Details | ✅ |
| note | `ZREPRINT` | Reprint packing slip | — | 🔒 scan: **"locked; access is unauthorized"** |
| note | `ZPACK02D` | Edited boxes | Dyeing Packing | 🔒 scan: **"locked; access is unauthorized"** |

The margin note next to the locked pair reads *"Before posting please allow
these T-codes"* — an **access** request, not a development request. Handled in
`BASIS-REQUEST-ZREPRINT-ZPACK02D.md`.

The `ZLABEL` screen in the scan is *Maintain Label Master*, group **Dyeing
(2002)**, with brand radio buttons **Kejriwal / Karishma / Microtex / Blank**
and an Execute button. No Fiori tile exists for it anywhere in the five spaces.

## 4. Dispatch and sales (user `KID_SD2`)

| Transaction | What it does | Fiori tile | Status |
| --- | --- | --- | --- |
| `ZDSTOCK` | Dyeing finish stock (daily stock report) | Packed Stock / Display Stock Overview | ✅ |
| `ZPACKLISTN` | Sales: create packing list | Packing List | ✅ |
| `ZPLIST01A` / `02A` / `03A` | Create / edit / delete packing list | Packing List | ✅ |
| `ZSDOBD` | Create challan | Delivery Challan | ✅ |
| `ZDEL` | Print challan | *(Output Management)* | ➡️ form template |
| `ZPACK` | Print packing list | *(Output Management)* | ➡️ form template |
| `ZPRP` | Packing box report | Packing Register | ✅ |
| `ZVLMOVE` | Transfer box store location (301 mvt, HU) | Post Goods Movement | ⚠️ **partial** |
| `VF01` | Create billing document | Create Billing Document | ✅ |
| `ZEINV` | E-invoice & e-way bill | eDocument Cockpit / E-Invoice–E-Way Bill | ✅ |
| `ZINVCN` | Print invoice | *(Output Management)* | ➡️ form template |
| `ZTRUCK` | Truck master | Truck Master | ✅ |
| `ZSALESN` | Sales report | Sales Register | ✅ |
| `ZBOXSTOCK` | Stock report — **denier, grade, shade, filament, packing type** | Packed Stock | ⚠️ **partial** |
| `ZCUST`, `ZSOREG`, `ZDSP_CORR` | Customer / order registers, dispatch correction | Customer Register, Sales Register, Dispatch | ✅ |
| `VA01`/`VA02`, `VL01N`/`VL02N`, `MIGO`, `MMBE`, `MB52` | standard | Manage Sales Orders, Manage Outbound Deliveries, Post Goods Movement, Display Stock Overview | ✅ |

### Why the two ⚠️ rows are partial

**`ZVLMOVE`** — the shipped `postGoodsMovement` handler reads HU *contents* from
`VEPO` and calls `BAPI_GOODSMVT_CREATE`, so it moves the stock but leaves
`VEKP` pointing at the old storage location. `ZVLMOVE` moves the HU itself.
Full analysis, test plan and fix in
[`ZVLMOVE-vs-POST-GOODS-MOVEMENT-HU.md`](ZVLMOVE-vs-POST-GOODS-MOVEMENT-HU.md).

**`ZBOXSTOCK`** — its selection screen offers *Type of Product, **Denier**,
**Filament**, Packing Type, Work Center*. `ZI_PACKED_STOCK` already carries
`ProductType`, `PackingType` and `WorkCenter` from `ZPP_PACK`, but **Denier and
Filament are not there** — they live on the material extension `ZZMARA`. Without
them the Packed Stock tile cannot reproduce the report the dispatch desk runs.

---

## 5. Scoreboard

| | Count |
| --- | ---: |
| Transactions named in the runbook | **~35** |
| Already covered by a live tile | **26** |
| Covered by Output Management form templates (planned, not app work) | 3 |
| Access / FLP-config items, no development | 3 — `ZREPRINT`, `ZPACK02D`, `CO03` |
| **Genuine development gaps** | **5** |

## 6. The five development gaps and their status

| # | Gap | Origin in the scan | Status |
| --- | --- | --- | --- |
| 1 | **Cancel production confirmation** | `CO13` / `ZCO11A` — *"Correction option not available"* | ✅ built — `apps/production-confirmation-cancel` |
| 2 | **WIP batch close / reopen** | `zbatch_cls` — *"Needed"* | ✅ built — `apps/wip-batch-close` |
| 3 | **Label master** | `ZLABEL` — *Maintain Label Master* | ⚠️ built, one VERIFY — `apps/label-master` |
| 4 | **Packed Stock: denier + filament** | `ZBOXSTOCK` selection screen | ✅ built — `ZI_PACKED_STOCK` extended |
| 5 | **HU move, not content move** | `ZVLMOVE` | 📋 analysed, handler fix specified |

Gap 3 carries one open item: the field list of the legacy table `ZPP_LABEL`
could not be read (ADT was unreachable from this session). The CDS isolates
every `ZPP_LABEL` field into a single marked block — one `SE11` look and one
edit finishes it. Everything else in that app is complete.

## 7. What is *not* a gap

Worth stating, because it saves work:

- **`ZREPRINT` / `ZPACK02D`** — the plant wrote *"locked; access is
  unauthorized"*, not *"missing"*. `ZPACK02D` is already replaced by the
  Dyeing Packing app; `ZREPRINT` is a print driver heading for an Output
  Management template. Both are role assignments today.
- **`ZDEL` / `ZPACK` / `ZINVCN`** — print programs. Per
  `PRT-OUTPUT-MANAGEMENT.md` these become one parameterised Adobe template per
  output object, not three apps.
- **`CO03`** — SAP already ships *Display Production Order*; it needs adding to
  the Production space, not building.
