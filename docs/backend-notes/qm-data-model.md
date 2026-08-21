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
