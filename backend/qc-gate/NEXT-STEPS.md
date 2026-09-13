# Where this stands — 28 Aug 2026, end of session

## Live in KSD already

Fifteen backend objects, all active, verified against the OData metadata:
six CDS views, two replacements, two action parameter structures, the
`ZQC_CONF_BATCH` table, both behaviour definitions and the service definition.
Six actions exposed, `__OperationControl` carrying all six.

## `ProductionLot` — activated 28 Aug, verified in the service

All three views are active and the field is live in the OData metadata:

```
Property Name="ProductionLot" Type="Edm.String" Nullable="false" MaxLength="10"
```

Six actions still exposed, `OrderBatch` still there, `ZI_QC_INSP_LOT` still
returns 151 rows for 151 rows in QALS.

Behaviour confirmed against real data: on the plant-2002 lot 890000000100,
`Batch` is `QM_TEST5`, `GreigeLot` echoes it, and **`ProductionLot` is blank** —
nothing links that lot to a plant batch, and the field says so instead of
repeating the batch back.

The apps are clear to build and deploy.

### What `ProductionLot` is, and why it has no fallback

Three different numbers travel with a greige delivery:

| Field | Source | Meaning |
|---|---|---|
| `VendorBatch` | `QALS-LICHN` | the supplier's own reference |
| `Batch` | `QALS-CHARG` | our batch as received, sitting in DRM1 |
| `ProductionLot` | `ZPP_BATCHN-LOTNO` | the lot it is **dyed under** in DPR1 |

The 301 transfer renames the yarn on its way to the floor:

```
T11072BCXXXXXXXXXX / AT1-5547  ->  T11072BCXXXXXXXXXX / BCT
T1505T34TXXTEST    / TEST123   ->  T1505T34TXXTEST    / 3254-TEST
```

So `ProductionLot` is blank when no plant batch record claims the delivery.
That blank is the answer. Defaulting it to `Batch` would look like an answer
and be wrong every time the rename applies.

## App changes, committed and ready to build

All three apps, in `apps/qc-*/webapp`:

- **Grey QC** — Release to Production button, greige-lot picker scoped to the
  plant's open batches, both lot numbers in the detail header and worklist.
- **Post-Dyeing** — Confirm Dyeing, operation 0010, work centre from
  `DyeingWorkCentre`.
- **Post-Winding** — Confirm Winding, operation 0020, work centre from
  `WindingWorkCentre`.
- Both in-process worklists gained plant batch, job card and greige lot;
  Post-Winding gained the order column it never had.

Every action call was diffed against the live `$metadata`: 12 of 12 parameters
for `releaseToProduction`, 15 of 15 for both confirmations, no extras.

The batch is never guessed. Where the lot resolves it (`BatchSource = 'C'`)
it is pre-filled; where it does not, the field stays empty and the worklist
says *pick at confirmation* so the technician knows before opening the lot.

Deploying also carries `patch-save3.js`, which is in the working copy but has
never reached KSD.

## Then: master data

Nothing is testable until plant 2002 has MICs, inspection plans, the `ZQC-UD`
selected set and inspection types on the greige and dyed materials. Six steps
in `PLANT-2002-QM-SETUP.md`.

## The one open decision

Does the greige inspection lot sit on the **supplier batch** (type 01 at goods
receipt) or on the **production lot** (type 08 at the 301 transfer)?

- Supplier batch: `ZI_QC_BATCH_BY_GREIGE` never matches, `OrderSource` stays
  blank on every grey lot, `ProductionLot` stays blank until someone links the
  batch. The app handles this — the operator picks the target lot at release.
- Production lot: `CHARG = LOTNO`, the order resolves, the anchor works as
  designed and `ProductionLot` fills itself in.

This is step 5 of the master-data plan and the only place where what is built
rests on something that could not be verified — there are no greige inspection
lots in plant 2002 to check against.

---

# Value helps on Batch and Supplier Lot — 29 Aug 2026

Live in KSD. Both dropdowns are on `ZC_QC_INSP_LOT`, so they appear in all
three QC apps at once — no app rebuild, no redeploy.

Four objects, all active:

| Object | Transport | What it does |
|---|---|---|
| `ZI_VH_QC_BATCH` | KSDK906759 | open lots grouped by plant + batch |
| `ZI_VH_QC_SUPPLIER_LOT` | KSDK906759 | open lots grouped by plant + `LICHN` |
| `ZC_QC_INSP_LOT` | KSDK906760 | two `@Consumption.valueHelpDefinition`, each bound to `Plant` |
| `ZUI_QC_INSPECTION` | KSDK906759 | exposes both views as `BatchVH` / `SupplierLotVH` |

**Why the service definition line was needed here** — corrected 30 Aug. I first
wrote that the `expose` is mandatory for any value help. It is not. Tested on
the Schedule service: `ZI_VH_PLANT` is *not* exposed in `ZUI_SCHEDULE`, and its
`srvd_f4` endpoint returns plants with status 200. The V4 runtime builds the F4
service from the annotation alone, and a Fiori Elements app follows the
`ValueListReferences` in `$metadata` to reach it.

The expose is needed for *these three apps* because they are freestyle: the
SelectDialog in `Worklist.controller.js` binds `/BatchVH` on the main service
rather than following the annotation. That is a consequence of how the dialog
was written, not a rule about value helps. `PlantVH` and `CompanyVH` were
already exposed for the same reason.

Service definitions do not accept `//` comments. SAP strips them on save and
reports *"Comments are not supported and will be deleted on save"*, which
cancels the activation. The comments in `zui_qc_inspection.srvd.srvdsrv` are
design-time documentation only; the active version in KSD has just the seven
`expose` lines.

## Verified end to end, not just activated

```
$metadata EntitySets ....... BatchVH, SupplierLotVH  (both present)
Batch      -> srvd_f4/sap/zi_vh_qc_batch/0001 ......... 200
SupplierLot-> srvd_f4/sap/zi_vh_qc_supplier_lot/0001 .. 200

GET .../ZI_VH_QC_BATCH?$filter=Plant eq '2002'
  -> AT1-5547  T11072BCXXXXXXXXXX  110/72 BRIGHT CATONIC TEST   1 open lot
  -> QM_TEST5  000010100034000120  C.P.F. ASSEMBLING LOG BOOK   1 open lot
```

Sixteen batches across the system: 13 in plant 1000, 2 in 2002, 1 in 7000.
Fewer than feared — plant 2002 is not empty after all, it just has two lots.

## Supplier Lot will stay empty, and that is the data

`QALS-LICHN` is blank on **all 152 inspection lots** in KSD — every plant,
every inspection type, open and closed. Nothing in this system fills it,
because these lots are not raised against a goods receipt carrying a vendor
batch. The dropdown is wired correctly and answers 200 with an empty
collection.

The number an operator means by "supplier lot" is `QALS-CHARG` on a type 01
or 08 lot — the `GreigeLot` column. On lot `010000000051` in plant 2002:

```
Batch = AT1-5547    GreigeLot = AT1-5547    VendorBatch = (blank)
```

On a greige lot the two are the same string, so **`ZI_VH_QC_BATCH` already
offers it**. That is why no third view was created.

### If a Greige Lot dropdown is wanted anyway

`zi_vh_qc_greige_lot.asddls` is written and ready but **not created in KSD**.
It differs from the batch view in one way: it excludes the type 89 in-process
lots, whose `CHARG` is the plant's own batch number rather than anything a
supplier sent. 86 open lots carry a greige lot (85 in plant 1000, 1 in 2002).

Three steps, all in Eclipse:

1. New DDL source `ZI_VH_QC_GREIGE_LOT` in `ZKGPL_QM`, paste the file, activate.
2. Add to `ZUI_QC_INSPECTION`: `expose ZI_VH_QC_GREIGE_LOT as GreigeLotVH;`
3. On `GreigeLot` in `ZC_QC_INSP_LOT`, the same annotation shape as `Batch`.

Say the word and it is a ten-minute job — the pattern is already proven.

## Three follow-on fixes — 29 Aug 2026, later

Deploying the first version turned up three faults, two of them mine.

**1. `sap.m.SelectDialog` has no `afterClose`.** I added
`oDialog.attachAfterClose(...)` to release the cached dialog. In UI5 1.136.18
that class fires only `confirm`, `search`, `liveChange`, `cancel` — checked
against the class metadata in the running app, not guessed. The handler threw
`TypeError: f.attachAfterClose is not a function` before opening anything,
which killed the Plant dropdown too, since all three now share
`_openValueHelp`. Replaced with one cached dialog per entity set, no teardown.

**2. The auto-fill read properties the request never asked for.** An OData V4
list binding derives `$select` from the properties actually bound in the
template. `Material` and `ProductionOrder` appear nowhere in the list, so they
were absent from the payload and `getProperty` returned `undefined` — the fill
silently did nothing while Plant, which is bound, worked. The context proved
it:

```
{Plant:'2002', Batch:'AT1-5547', MaterialName:'...', MaterialCount:1, OpenLotCount:1}
```

Fixed with an explicit `$select` in the binding parameters.

**3. Every stage's dropdown offered every other stage's batches.** The value
help had no inspection-type filter, so Post-Dyeing listed raw-material
batches its own worklist can never return. `InspectionType` is now a key on
both views and the apps filter on their own type through `_inspTypeFilter`,
shared with the worklist query. No batch carries open lots of two types, so
this adds no duplicate rows.

### Auto-fill rules

Picking a Batch or Supplier Lot fills Plant, Material and Production Order.
Only where the pick actually settles them:

| Field | Filled when | Why |
|---|---|---|
| Plant | always | a key of the view — exactly one value per row |
| Material | `MaterialCount = 1` | 4 of 16 batches carry more than one (QM_TEST 3, F023000004 3, QM_TEST1 2, QM_TEST4 2) |
| Production Order | `OrderCount = 1` and non-blank | blank on 15 of the 16 |

Where a batch has several materials the dialog says so — "3 materials" in
place of the description — instead of showing one and hiding the rest.

Verified against the live service: `R014300036` fills Batch, Material and
Plant; `QM_TEST` fills Batch and Plant and correctly withholds Material;
`AT1-5547` fills all four including order `000001008691`.

## Grey QC was reading one inspection type instead of two

`qc-raw-material/webapp/Component.js` had `inspectionType: ["01"]`. Step 6 of
PLANT-2002-QM-SETUP.md says Grey QC reads **01 and 08** — purchased yarn
arrives on a goods receipt and raises 01, in-house greige never does and
raises 08. Measured in QALS on 2026-08-29:

```
01 -> 2002 x1,  7000 x2
08 -> 1000 x87, 7000 x12
89 -> 1000 x49, 2002 x1
```

So `["01"]` hid every greige lot in plant 1000 — all 87 of them. Now
`["01", "08"]`. This was invisible until the value help started filtering by
type; the worklist had the same gap all along.

## Post-Dyeing and Post-Winding cannot return a row yet

Their inspection types are **03** and **04**. `QALS` holds no lot of either
type, in any plant, open or closed. That is the master-data gap in steps 4
and 5 of PLANT-2002-QM-SETUP.md — the plans and material QM views that make
an order release raise 03 and 04 do not exist yet.

Both apps are configured correctly. Until that data exists their worklists
return nothing and their Batch dropdowns are empty, and the dropdown now says
so: *"No batch has an open inspection lot for this stage."* The 11 type-89
batches those dropdowns were showing before belong to no app's stage — 89 is
the manual lot type plant 1000 has been using.
