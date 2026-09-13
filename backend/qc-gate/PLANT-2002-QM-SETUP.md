# Plant 2002 QM master data — what has to exist before anything is testable

Read from KSD on 28 Aug 2026. Nothing here is assumed.

## Where 2002 stands today

| Object | Plant 2002 | Elsewhere |
|---|---|---|
| Master inspection characteristics (`QPMK`) | **none** | 5 in plant 1000, 1 in 7000 |
| Inspection plans (`PLKO`, type Q) | **none** | 4 in plant 1000, 2 in 7000 |
| Material QM views (`QMAT`) | **1 material, type 89 only** | 1000 has 08 and 89; 7000 has 01 and 08 |
| UD selected sets (`QPAM`, catalog 3) | standard 01–1602 plus a custom `UD-RM` | `ZQC-UD` exists in **plant 1000 only** |
| Inspection lots (`QALS`) | **1**, type 89 | 1000: 136, 7000: 14 |

So there is not one inspection lot the three apps could open, and no plan that
would create one. The code is not the blocker.

`UD-RM` in 2002 carries exactly two codes, both under code group `01`:
`A` valuated **A** (accept) and `R` valuated **R** (reject). The nine-code
`ZQC-UD` set the apps were built around does not exist in this plant.

## The ZQC-UD codes, as they actually are

Read from `QPAC`. Note the accepting codes are **A, A1 and SP** — three of nine.

| Code | Valuation | |
|---|---|---|
| `A`   | A | accept |
| `A1`  | A | accept |
| `SP`  | A | accept |
| `CLQ` | R | reject |
| `DG`  | R | reject |
| `JL`  | R | reject |
| `PQ`  | R | reject |
| `RD`  | R | reject |
| `ST`  | R | reject |

`QAVE-VBEWERTUNG` stores this valuation on the lot when the decision is made,
which is why the saver no longer carries a code list of its own.

## What to create, in order

Each step depends on the one above it.

### 1. UD selected set for plant 2002 — Customizing, not master data

`ZQC-UD` is a catalog-type-3 selected set. Type 3 is Customizing, so `QS41`
and `QS51` refuse it. Use the views:

- `V_QPGR_UD` — code group `ZQC-UD` (plant independent, already exists)
- `V_QPCD_UD` — the nine codes (already exist)
- `V_QPAM_UD` — **the selected set, per plant. This is the missing one.**
  Create `ZQC-UD` for plant `2002`.
- `V_QPAC_UD` — the nine code entries in that set, each with its valuation
  as in the table above

Underscores are not allowed in catalog keys. Hyphens are, which is why the
name is `ZQC-UD`.

### 2. Master inspection characteristics — QS21, plant 2002

Sixteen quantitative characteristics, from the yarn test catalogue. Create as
**complete copy** (not reference) so each carries its own limits.

| MIC | Unit | Dec | Standard |
|---|---|---|---|
| `DENIER`   | — | 1 | ISO 2060 / ASTM D1907 |
| `DEN_NOM`  | — | 0 | nominal, from the material |
| `ELONG`    | % | 1 | ISO 2062 / ASTM D2256 |
| `TENACITY` | CN/DTEX | 2 | ISO 2062 / ASTM D2256 |
| `FILAMENT` | — | 0 | ASTM D2259 |
| `BWS`      | % | 2 | ISO 18067 |
| `OPU`      | % | 2 | ISO 18066 |
| `MOISTURE` | % | 2 | ISO 6741-1 |
| `EVENNESS` | % | 2 | ASTM D1425 |
| `NIPS`     | — | 0 | ASTM D4724 |
| `CRIMP`    | % | 1 | ISO 16549 |
| `PKG_DENS` | G/CM3 | 3 | no published standard |
| `PKG_HARD` | — | 0 | no published standard |
| `TRAVERSE` | MM | 0 | — |
| `PKG_DIA`  | MM | 0 | — |
| `PKG_WT`   | KG | 3 | ISO 5688 |

Plus one qualitative characteristic for shade, using catalog type 1 with a
selected set — needed for post-dyeing.

Control indicators that matter: quantitative, target value with upper and
lower limits, and **summarised recording** so `QAMR` gets one row per
characteristic. The apps read `QAMV` for the spec and `QAMR` for the result;
anything recorded as single values will not appear.

### 3. Sampling procedure — QDV1

One fixed-sample procedure is enough to start. Without it the plan
characteristics cannot be saved.

### 4. Inspection plans — QP01, plant 2002

Three plans, one per gate. Usage `5` (general), status `4` (released).

| Plan | Inspection type | Characteristics |
|---|---|---|
| Greige | 01 | DENIER, DEN_NOM, ELONG, TENACITY, FILAMENT, OPU, MOISTURE, EVENNESS, NIPS, CRIMP |
| Post-dyeing | 03 | DENIER, ELONG, TENACITY, BWS, MOISTURE, shade |
| Post-winding | 04 | DENIER, MOISTURE, PKG_DENS, PKG_HARD, TRAVERSE, PKG_DIA, PKG_WT |

Post-winding is the one that has to match Grey QC in shape — same physical
tests, plus the package build characteristics.

Assign each plan to its materials by material assignment inside QP01. The
materials in play, from the 2026 batches in `ZPP_BATCHN`:

- greige — `T1505T34TXXTEST`, `T300962NYLONDYEDXX`, `T11072BCXXXXXXXXXX`,
  `T150048SDSSNXXXXXX`, `T155072BTSSNXXXXXX`
- dyed — `D310072BTDXXXXTEST`, `D30096NIMPTYDYED01`, `D110036BTDXXXXXXX1`,
  `D150000XXXXXXXXX01`, `D155072BTXXXXXXX01`

### 5. Material QM view — MM02, QM view, plant 2002

Inspection setup per material. Copy the pattern plant 1000 uses for type 08:
`AKTIV = X`, `PPL = X` (plan assignment), `INSMK = X` where stock relevance
is wanted.

| Material | Type | Stock relevant | Why |
|---|---|---|---|
| greige | **01** | **yes** | the goods receipt posts to inspection stock, so a rejected lot cannot be released by the usage decision |
| dyed | **03** | no | in-process, mid-order — there is no stock posting to lean on, which is exactly why the confirmation gate exists |
| dyed | **04** | no | same |

Stock relevance on 01 is the one that carries weight. Without it the greige
goods receipt lands in unrestricted stock and the usage decision has nothing
to release — `releaseToProduction` becomes the only control there is.

### 6. Then create a test lot

With 1–5 in place, a goods receipt on a greige material raises a type 01 lot
automatically. For the two in-process gates, releasing a production order
raises 03 and 04. Nothing has to be created by hand.

## The order this has to happen in

```
UD selected set (2002)  ->  MICs  ->  sampling procedure  ->  plans
                                                              |
                                       material QM view  <----+
                                                              |
                                              goods receipt / order release
                                                              |
                                                          first lot
```

## What the apps need on top

- The three apps filter on inspection type: Grey `01` and `08`,
  Post-Dyeing `03`, Post-Winding `04`. Those are already in `Component.js`.
- `ZQC-UD` must exist for 2002 or the usage decision dialog will offer the
  wrong codes.
- Storage locations for `releaseToProduction`: from `DRM1` to `DPR1`,
  movement type `301`.

---

# FINDING, 28 Aug 2026 — the greige lot was real until 2013, then abandoned

Checked before implementing "raise the greige lot on the production lot". The
decision cannot be implemented as stated, and the reason turns out to be more
interesting than a mislabelled field.

## LOTNO is a lot number the plant stopped filling in

My first reading of the data was that `ZPP_BATCHN-LOTNO` is a yarn type code:
131,562 rows in plant 2002 carry only 410 distinct values, nine of which cover
~115,000 rows (`TEX` 29,649, `BCT` 26,586, `BRT` 21,979, `ROTO` 11,838 ...).

That reading is wrong. Grouped by material and dated, the field splits cleanly
in two. `T155072BTSSNXXXXXX`:

| LOTNO | rows | first | last |
|---|---|---|---|
| `P-295`   | 312 | 2012-10-24 | 2013-04-15 |
| `5-2251T` | 147 | 2012-09-06 | 2012-11-12 |
| `P-317`   | 132 | 2013-04-14 | 2013-07-01 |
| `5D-506`  |  90 | 2012-11-20 | 2013-03-10 |
| `4-2250T` |   9 | 2012-07-30 | 2012-08-03 |
| **`BRT`** | **15,096** | **2002-02-13** | **2026-03-25** |

`T150048SDSSNXXXXXX` behaves identically: 68 real lots confined to 2012–13,
then `TEX` for 7,299 rows from 2013-07-02 to last month.

Real lot numbers, each consumed over a few weeks — exactly what a lot looks
like. And then one constant per material spanning **twenty-four years**.

**The plant recorded genuine greige lot numbers until roughly mid-2013 and
then stopped.** Everything since carries the yarn quality as a placeholder.
The free-text damage is visible too: `" 5D-506"` with a leading space.

## Consequences

- `LOTNO` cannot key anything current. For every batch since 2013 it is a
  constant, so `ZI_QC_BATCH_BY_GREIGE`, which groups on it, would collapse
  26,586 rows under `BCT` and return `max( ProductionOrder )` across all of
  them.
- Renaming the field `YarnType` would be wrong for the 2012–13 rows, where it
  really is a lot. It is exposed as `GreigeLotRef` instead — a reference that
  is displayed and never resolved on.
- `ZI_QC_ORDER_CONTEXT.GreigeLotCount` counts a placeholder, not lots.

## The 301 pools stock rather than renaming a lot

The same abandonment shows in the stock. The transfer's receiving batch is the
type code:

```
T11072BCXXXXXXXXXX   AT1-5547   DRM1  ->  BCT         DPR1
T11072BCXXXXXXXXXX   AT12-5634  DRM1  ->  BCT         DPR1
T1505T34TXXTEST      TEST123    DRM1  ->  3254-TEST   DPR1
T1505T34TXXTEST      XYZ        DRM1  ->  3254-TEST   DPR1
```

Many supplier lots in, one standing bucket out. Confirmed in `MCHB`:

| Location | distinct batches (T% materials) | character |
|---|---|---|
| `DRM1` | 745 rows | real supplier lots — `AT1-5364`, `AT/3-5006L`, `AT12-5402` |
| `DPR1` | **33** | type codes — `TPM` (25 materials), `TEX` (23), `BCT` (12) |

`DPR1` carries `" TPM"` and `" TEX"` with leading spaces and `CAT DUP` beside
`CAT DUPION` — a free-text bucket, not a batch.

A greige inspection lot raised on the DPR1 batch would therefore be raised on
`BCT`: 12 materials, 1,641 kg, pooled from many supplier lots. The result would
not describe any identifiable yarn.

## Two further constraints found

- `MSEG-AUFNR` is blank on every 301. The transfer carries no production order,
  so there is no route from supplier lot to order through the movement either.
- Type 08 lots (plant 1000) carry no `MBLNR`, `EBELN` or `LIFNR`. A type 08 lot
  cannot be traced back to what created it.

## Decision taken

**The greige inspection lot sits on the supplier batch in `DRM1`, inspection
type 01 at goods receipt.** It is the only identifier in this system that
describes real yarn. The order is not auto-resolved — nothing records which
supplier lot fed which batch — so the operator picks it, which is what the
existing picker already does.

Step 5 below stands as originally written: type 01, stock relevant.

### Roadmap, not now

Making `DPR1` carry the supplier lot (or `ZPP_BATCHN-BATCHNO`) instead of the
type code would restore end-to-end traceability and make type 08 viable. That
changes how the floor issues material and breaks with 13 years of convention.
It is a project to decide deliberately, not a step in a QC build.

---

# PROGRESS, 28 Aug 2026 — steps 1 to 3 complete

## Step 1 — `ZQC-UD` selected set, plant 2002 ✓

Created via `SM30` on `V_QPAM_UD` / `V_QPAC_UD` (`QS51` refuses catalog type 3).
Customizing request `KSDK906757`.

Verified in `QPAM` / `QPAC`: header status `2` Released, nine codes, valuations
matching plant 1000 exactly.

```
A    A  100      CLQ  R  50      Code group ZQC-UD on all nine
A1   A   90      DG   R  60
SP   A   80      JL   R  40
                 PQ   R  60
                 RD   R  50
                 ST   R  70
```

`Def. Group` and `Def. Code` deliberately left blank — a default UD code would
pre-select an outcome for the technician, which is the opposite of a gate.

## Step 2 — sixteen MICs, plant 2002 ✓

All sixteen created in `QS21`, one version each, `STEUERKZ` identical across
the set (`XX XXX=   X`).

**The plan originally said to bake limits into each MIC. That was wrong** and
was corrected before building: denier tolerance differs per yarn count, so
limits belong in the inspection plan. The MICs are measurement definitions —
limit indicators ticked, values blank — created as **Incomplete Copy Model**,
which is what lets SAP save them without spec values.

Control indicators, identical on all sixteen:

```
page 1   Lower Specif. Limit / Upper Specif. Limit / Check Target Value
         Sample: all clear (the plan assigns the sampling procedure)
         Summ. Recording  +  Required Charc
page 2   Fixed Scope / No Documentation / Record Measured Vals
         Print / No Formula
```

`Summ. Recording` and `Record Measured Vals` are the two that matter: the apps
read `QAMR`, and single-result recording writes elsewhere.

### Units — what this system actually has

`CN/DTEX` does not exist, and neither does any tex- or centinewton-based unit.
`T006A` holds only:

```
%   %        MM  mm       RHO  g/cm3      (internal key RHO, displays g/cm3)
G   g        KG  kg       DEN  DEN        N  N
```

So `TENACITY` carries **no unit**; `cN/dtex` lives in its Short Text instead.
Creating the unit properly in `CUNI` is possible but `MSEHI` is only three
characters, so it would be a key like `CDT` displaying `cN/dtx`, and it needs a
dimension decision. Worth doing only if the unit is wanted on QC certificates.

| MIC | Unit | Dec | | MIC | Unit | Dec |
|---|---|---|---|---|---|---|
| `DENIER` | `DEN` | 1 | | `CRIMP` | `%` | 1 |
| `DEN_NOM` | `DEN` | 0 | | `PKG_DENS` | `g/cm3` | 3 |
| `ELONG` | `%` | 1 | | `PKG_HARD` | — | 0 |
| `TENACITY` | — | 2 | | `TRAVERSE` | `mm` | 0 |
| `FILAMENT` | — | 0 | | `PKG_DIA` | `mm` | 0 |
| `BWS` | `%` | 2 | | `PKG_WT` | `kg` | 3 |
| `OPU` | `%` | 2 | | `MOISTURE` | `%` | 2 |
| `EVENNESS` | `%` | 2 | | `NIPS` | — | 0 |

### Gotcha worth remembering

A **Released** MIC cannot be edited in place — SAP spawns a new version. The
first `DENIER` ended up as two same-dated versions that way. Set everything
first and make **Released the last action before save**.

## Step 3 — `ZQC-FIX` sampling procedure ✓

Client-level, so plant 2002 picks it up automatically.

```
Sampling Type      Fixed sample
Valuation Mode     Attributive inspection nonconf. units
Control Chart Type (blank)
Determination Rule 10  Fixed sample
Inspection Points  Without
Multiple Samples   No
```

**Why attributive nonconforming units.** It counts sampled units outside the
plan's limits and fails the characteristic when the count exceeds the
acceptance number. Set acceptance to `0` and any out-of-spec reading fails.

Two alternatives were rejected: `Mean value within tolerance range` valuates
the average, so five good cheeses and one badly off can pass — the exact defect
this exists to catch. `Variable insp. s-Method` is statistical lot acceptance
and can reject a lot where every reading is in spec.

With determination rule `10`, **sample size and acceptance number live on the
plan characteristic**, not here. One procedure serves all sixteen.

## Step 4 — blocked, and on what

Three plans in `QP01`. Needs, per characteristic per plan: target, lower limit,
upper limit, sample size, acceptance number — **per yarn count**, since limits
differ between `T150048SDSSNXXXXXX` (150/48) and `T11072BCXXXXXXXXXX` (110/72).

These are the plant's real quality specs and cannot be invented. A guessed
denier tolerance either passes bad yarn or rejects good yarn; either way the
gate is worse than no gate.

Step 5 (material QM views) does not depend on them and can be done first.
