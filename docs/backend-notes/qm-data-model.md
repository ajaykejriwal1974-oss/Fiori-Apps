# QM data model for the QC apps — verified field reference

**Verified against `DD03L` in KSD client 500 on 2026-08-21.** Nothing here is
assumed. Every field below was read from the dictionary before a line of CDS
was written, because three of the four defects we spent 21 August chasing came
from guessing at field names (`ERNAME`/`ERNAM`, `ISMNEH`, and the whole
`ZPP_LABEL` rebuild).

## Corrections to Specification v2.0

| v2.0 said | Actually | Consequence |
| --- | --- | --- |
| Vendor batch is `QALS-LICHA` | **`QALS-LICHN`**, CHAR 15 | The Lot no. header field in the stage 1 app binds to `LICHN` |
| Read via CDS custom entity + query class | **Plain CDS view entities** | `QALS`, `QAMV`, `QAMR` are transparent tables. A custom entity would mean hand-writing filtering, paging and sorting in ABAP for no benefit. Custom entities are for data the database cannot serve; this is not that. Writes still go through BAPIs. |
| MIC name up to 8 characters | Confirmed — `QAMV-VERWMERKM` is CHAR 8 | The `S1_DEN` / `S2_INOUT` style codes fit |

## QALS — inspection lot header

| Field | Type | Meaning |
| --- | --- | --- |
| `PRUEFLOS` | NUMC 12, key | Inspection lot |
| `WERK` | CHAR 4 | Plant |
| `ART` | CHAR 8 | Inspection type — 01 / 03 / 04 |
| `HERKUNFT` | CHAR 2 | Lot origin |
| `MATNR` | CHAR 40 | Material |
| `KTEXTMAT` | CHAR 40 | Material short text — already on the lot, no `MAKT` join needed |
| `CHARG` | CHAR 10 | Batch |
| `LICHN` | CHAR 15 | **Vendor batch** — the supplier lot number |
| `AUFNR` | CHAR 12 | Production order |
| `KTEXTLOS` | CHAR 40 | Lot short text |
| `ENSTEHDAT` | DATS | Created on |
| `PASTRTERM` / `PAENDTERM` | DATS | Planned start / end |
| `LOSMENGE` | QUAN 13 | Lot quantity — unit in `MENGENEINH` |
| `GESSTICHPR` | QUAN 13 | Total sample size — unit in `EINHPROBE` |
| `STAT34` | CHAR 1 | Results confirmed |
| `STAT35` | CHAR 1 | Usage decision made |
| `DYNREGEL` | CHAR 3 | Dynamic modification rule — how tier 2 skipping is enforced |
| `PRSTUFE` | NUMC 4 | Inspection stage in the dynamic rule |

## QAMV — characteristic specification per lot

Key: `PRUEFLOS` + `VORGLFNR` (NUMC 8) + `MERKNR` (NUMC 4).

| Field | Type | Meaning |
| --- | --- | --- |
| `VERWMERKM` | CHAR 8 | Master inspection characteristic |
| `KURZTEXT` | CHAR 40 | Characteristic short text |
| `STEUERKZ` | CHAR 30 | Control indicators, one flag per position |
| `STELLEN` | INT1 | Decimal places |
| `MASSEINHSW` | UNIT 3 | Unit of measure |
| `SOLLWERT` | **FLTP** | Target value |
| `TOLERANZUN` / `TOLERANZOB` | **FLTP** | Lower / upper specification limit |
| `SOLLWNI`, `TOLUNNI`, `TOLOBNI` | CHAR 1 | **Is-initial flags — see the trap below** |
| `KATALGART1` | CHAR 1 | Catalog type — set means the characteristic is qualitative |
| `AUSWMENGE1` | CHAR 8 | Selected set |

## QAMR — summarised result

Same three-part key as `QAMV`, so the join cannot fan out.

| Field | Type | Meaning |
| --- | --- | --- |
| `MITTELWERT` | FLTP | Mean value — the quantitative result |
| `MITTELWNI` | CHAR 1 | Is-initial flag for the mean |
| `GRUPPE1` / `CODE1` | CHAR 8 / CHAR 4 | Code group and code — the qualitative result |
| `ANZFEHLER` | INT4 | **Number of defects** — this is where an ISO 2859-1 attribute result lands |
| `ISTSTPUMF` | INT4 | Actual sample size inspected |
| `MBEWERTG` | CHAR 1 | Valuation — A accepted, R rejected |
| `PRUEFER` | CHAR 12 | Inspector |
| `PRUEFDATUB` | DATS | Inspection end date |
| `PRUEFBEMKT` | CHAR 40 | Inspector comment |
| `SATZSTATUS` | CHAR 1 | Record status |

`ANZFEHLER` is the field that makes design rule 6.2 of the specification work:
an attribute characteristic is one row holding a defect count over the sample,
not one row per package inspected.

## The FLTP trap

`SOLLWERT`, `TOLERANZUN`, `TOLERANZOB` and `MITTELWERT` are **floating point**,
and floating point cannot distinguish *zero* from *not maintained*. SAP
therefore carries a companion flag for each — `SOLLWNI`, `TOLUNNI`, `TOLOBNI`,
`MITTELWNI` — set to `X` when the value is initial.

**The UI must check the flag before rendering the limit.** Skip this and every
unmaintained lower limit displays as `0.00`, every result reads as
above-minimum, and the app silently valuates against a limit that was never
set. Both views expose the flags alongside the values for exactly this reason.

## Why views, not custom entities

`QALS`, `QAMV` and `QAMR` are transparent tables, so the database can filter,
sort and page them. A custom entity with a query class means re-implementing
all three by hand in ABAP — which is what we did for Pallet Stock and Delivery
Challan, correctly, because those read from sources the database could not
serve directly.

Writes are different. There is no supported way to write a QM result with a
plain update, so the behaviour pool calls the standard BAPIs:

| Purpose | BAPI |
| --- | --- |
| Read characteristic requirements | `BAPI_INSPCHAR_GETREQUIREMENTS` |
| Write one result | `BAPI_INSPCHAR_SETRESULT` |
| Close the operation | `BAPI_INSPOPER_RECORDRESULTS` |
| Usage decision | `BAPI_INSPLOT_SETUSAGEDECISION` |
| Commit | `BAPI_TRANSACTION_COMMIT` via `DESTINATION 'NONE'` |

The `DESTINATION 'NONE'` pattern is the one established in
`ZBP_I_PROD_CONFIRMATION` — it separates the update task LUW so a failure in
one characteristic does not roll back the whole batch of results.

---

## Design changes made during the build

Two things in Specification v2 turned out to be wrong once the code was written.

### The draft table is not needed

v2 called for `ZQC_RESULT_DRAFT` because a fastness battery is not entered in
one sitting — the perspirometer runs for four hours and the technician comes
back. The reasoning was that QM has no draft concept for results.

That is wrong. **`BAPI_INSPCHAR_SETRESULT` persists a result without confirming
the operation**, and `QAMR-SATZSTATUS` already distinguishes recorded from
confirmed. So the app has two genuine save levels with no custom table at all:

| Button | Call | Effect |
| --- | --- | --- |
| **Save** | `BAPI_INSPCHAR_SETRESULT` per changed row | Results persisted, operation still open, technician can leave and return |
| **Record Results** | `BAPI_INSPOPER_RECORDRESULTS` | Operation confirmed, `QALS-STAT34` set |
| **Usage Decision** | `BAPI_INSPLOT_SETUSAGEDECISION` | Lot closed, `QALS-STAT35` set |

One fewer Z table, and the behaviour is standard rather than bolted on.

### Composition, not association

The first draft of `ZI_QC_INSP_LOT` reached the characteristics by association.
RAP only permits an updatable child inside a **composition**, and the whole
point of the detail screen is editing result rows in place. Changed to
`composition [0..*] of ZI_QC_INSP_CHAR`, with `association to parent` on the
child.

Worth noting the tension: `ZPP_BATCHN` is still reached by association
precisely *because* it must not fan out rows. Composition where the child is
owned and edited; association where the data is merely related.

## One service, three apps

The three QC apps share `ZUI_QC_INSPECTION` and differ only by a filter on
`InspectionType`, set in each `Component.js`:

| App | BSP | Inspection type | Intent |
| --- | --- | --- | --- |
| Raw Material QC | `ZQC_RAW_DYE` | `01` | `QcRawMaterial-inspectKejriwal` |
| Post-Dyeing QC | `ZQC_POST_DYE` | `03` | `QcPostDyeing-inspectKejriwal` |
| Post-Winding QC | `ZQC_POST_WIND` | `04` | `QcPostWinding-inspectKejriwal` |

The backend is built, activated and tested once. A defect found in one app is
fixed in one place — which, after spending 21 August fixing the same class of
bug three times across three separately-built apps, is the point.

## Lessons from 21 August applied at the start

| Lesson | Applied |
| --- | --- |
| Label Master bootstrapped from `ui5.sap.com`, unreachable from the plant | All three `index.html` files use `src="resources/sap-ui-core.js"` |
| Component container height defaults to auto → blank page, clean console | The `height: 100%` block is in all three, with the comment explaining why |
| 20 of 25 apps sit in `$TMP` and cannot transport | `ui5-deploy.yaml` names `ZKGPL_FIORI` from the first deployment |
| A projection behaviour definition left inactive broke the whole service | Both BDEFs written together; activate parent before projection |
| Guessed field names cost three defects | Every field read from `DD03L` first |

## Open before deployment

1. **Inspection types.** `ZI_QC_INSP_LOT` filters on `'01','03','04'` and their
   `Z`-prefixed variants. Confirm which are actually configured in KSD — if the
   plant uses custom types, that `where` clause needs the real values.
2. **`OperationNumber` is hard-coded to `00000010`** in `Detail.controller.js`
   `onRecord`. That holds while each inspection plan has a single operation.
   The moment a plan has two, this must come from the selected characteristic.
3. **Action binding paths** use
   `com.sap.gateway.srvd.zui_qc_inspection.v0001.<action>`. Verify against the
   real `$metadata` after the service binding is published — this string is
   generated from the service definition name and is easy to get wrong.
4. **Value help for Plant** is a stub (`onPlantHelp`). Wire it to `PlantVH`
   once the service is live.
