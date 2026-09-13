# QC gates - the built pieces

## The model

Passing QC is what performs the next physical step. Nothing is blocked,
because the postings can only be made through QC.

| App | Inspects | Anchors on | Passing posts |
|---|---|---|---|
| Grey QC | the greige lot | production order | the transfer from RM location to production location |
| Post-Dyeing | the dyed batch | plant batch + job card | the dyeing confirmation |
| Post-Winding | the wound cheeses | plant batch + job card | the winding confirmation |

Order level and batch level answer different questions and are kept apart.
An order is raised big and split into many small batches, so greige lot, job
card, work centre and batch number are batch-level facts. Only the greige
material, the dyed material and honest totals are order-level.

## Two round trips, not one

Save records the results and posts the usage decision. The usage decision
moves stock out of inspection in its own update task. A transfer posted in
that same LUW would read stock that has not moved yet and fail on a deficit.

So the follow-on actions require a usage decision that is already on the
database. The app shows them as a second press after Save. Instance feature
control disables them until then; the actions re-check, because feature
control shapes a button and enforces nothing.

## Activate in this order

1. `ZI_QC_JOB_BY_BATCH`      job card rolled up to one row per plant batch
2. `ZI_QC_BATCH_JOB`         ZPP_BATCHN + its job card, one row per batch
3. `ZI_QC_ORDER_CONTEXT`     order-level totals only
4. `ZI_QC_BATCH_BY_GREIGE`   greige lot -> production order
5. `ZI_QC_BATCH_BY_NO`       batch number -> year, order, job card
6. `ZI_QC_LOT_ORDER`         inspection lot -> its order and its batch
7. `ZI_QC_INSP_LOT`          replaces the existing view
8. `ZC_QC_INSP_LOT`          replaces the existing view
9. `ZQC_CONF_BATCH`         new table - confirmation to plant batch
10. `ZD_QC_RELEASE_PROD`     new action parameter
11. `ZD_QC_CONFIRM_PROD`     new action parameter
12. `ZI_QC_INSP_LOT` BDEF    adds the three actions
13. `ZBP_I_QC_INSP_LOT`      the three blocks in locals-additions.abap
14. `ZC_QC_INSP_LOT` BDEF    exposes the three actions
15. `ZUI_QC_INSPECTION`      exposes ZI_QC_BATCH_JOB as OrderBatch

3, 4 and 5 need 2. 6 needs 4 and 5. 7 needs 3 and 6. 8 needs 7.
12 needs 10 and 11. 13 needs 9 and 12. 14 needs 13.

## How a lot finds its order and its batch

| Lot | QALS-AUFNR | OrderSource | BatchSource |
|---|---|---|---|
| Post-Dyeing 03  | filled | `O` | `C` if QALS-CHARG is the plant batch, else blank |
| Post-Winding 04 | filled | `O` | same |
| Grey 01 / 08    | blank  | `G` via ZPP_BATCHN-LOTNO | `G`, indicative only |
| Grey, unassigned| blank  | ` ` | ` ` |

`BatchSource = ' '` on an in-process lot means the operator must pick a batch
from the order before anything can be confirmed. That is what `OrderBatch` in
the service is for. Probe 13 decides how often that happens.

## Settled on 28 Aug against the live system

- **Confirmations unblocked.** ZCO11A calls `BAPI_PRODORDCONF_CREATE_TT` and
  then commits - that is the whole posting. The saver calls the same BAPI and
  lets the RAP framework commit. Operation `0010` is dyeing, `0020` is
  winding; both exist in the routing and both are confirmed in 2002 today.
- **`ZPP_CONFIRM` is not the confirmation record.** `COMPONENT` holds
  `C0000000xx` material numbers at 0.1-15 kg a row - dye and chemical
  consumption per batch. The confirmations do not write it.
- **Movement is `301`, `DRM1` to `DPR1`**, not 311, and it carries a
  **receiving batch**: the supplier batch becomes the production greige lot
  that `ZPP_BATCHN-LOTNO` holds.
- **The UD code list is gone.** `QAVE-VBEWERTUNG` carries the valuation, so
  the saver reads it. The accepting codes in `ZQC-UD` are `A`, `A1` and `SP` -
  the constant I had was wrong as well as duplicated.
- **`JOBNO` = `BATCHNO`**, one job card per batch. `ZI_QC_JOB_BY_BATCH` will
  always return a count of 1; kept as a guard, costs nothing.
- **`AUFNR` is filled on every batch**, so the order anchor holds. And one
  order routinely carries five or six batches, so `BatchCount > 1` is the
  normal case the design was built for.

## Still open

- **Nothing is testable until plant 2002 has QM master data.** No MICs, no
  plans, no `ZQC-UD` selected set, inspection type 89 on one material only.
  See `masterdata/PLANT-2002-QM-SETUP.md`.
- `patch-save3.js` is still built but never deployed or tested.

## Activated in KSD on 28 Aug 2026

All eight CDS objects are live in package `ZKGPL_FIORI`, transport
`KSDK906754`. `sap_inactive_objects` returns empty.

Three CDS constraints turned up during activation, each with a note now in the
source explaining the choice rather than just the workaround:

- **`@EndUserText.label` is capped at 40 characters.** Five labels were over
  and were shortened.
- **A `QUAN` field needs a unit reference.** `ZDE_CHEESES` is typed `QUAN`, but
  a cheese is counted, not measured - pointing it at `BatchUnit` would render
  85 cheeses as "85 KG". Cast to `abap.dec(15,0)` instead.
- **A `UNIT` field can be neither aggregated nor cast.** `max( BatchUnit )` is
  rejected outright and so is `cast( BatchUnit as abap.char(3) )`. So there is
  no `OrderUnit`: the order total is a plain number and the unit stays at batch
  level where it is single-valued. It is blank on every 2026 batch anyway.

`count( distinct … )` and `sum( case … )` both activated without complaint -
those were the two constructs I was least sure of.

### Verified against live data

- `ZI_QC_INSP_LOT` returns **151 rows** for 151 rows in `QALS`. The joins do
  not multiply a lot.
- `ZI_QC_ORDER_CONTEXT` for order `000001008695`: 6 batches, 5 open,
  **GreigeLotCount 2**, 5400.000 quantity, 4186 cheeses - matching the batch
  records by hand. That count of 2 is the split (TEST1 on two batches,
  3254-TEST on four) that the order/batch separation exists to expose.

### Two objects still to write

`ZD_QC_RELEASE_PROD` and `ZD_QC_CONFIRM_PROD` are not yet created in Eclipse.
They are only needed by the BDEF actions, which come after this layer.

## Second pass, 28 Aug - actions layer

Activated through ADT:

- `ZD_QC_RELEASE_PROD`, `ZD_QC_CONFIRM_PROD` - abstract entities. Quantities
  are plain `dec`, not `quan`: a quantity type demands a unit reference and
  these are parameter structures, not a data model.
- `ZQC_CONF_BATCH` - the confirmation-to-batch link table. `RU_LMNGA` and
  `RU_XMNGA` are `QUAN`, so both needed
  `@Semantics.quantity.unitOfMeasure : 'zqc_conf_batch.meinh'`.
- `ZUI_QC_INSPECTION` - now exposes `ZI_QC_BATCH_JOB` as `OrderBatch`.
  Service definitions reject comments outright: "Comments are not supported
  and will be deleted on save" is an activation error, not a warning.

### What ADT cannot reach

The MCP server addresses behaviour definitions at the old BOPF path
`/sap/bc/adt/bopf/bdef/sources/`, not the RAP path
`/sap/bc/adt/bo/behaviordefinitions/`. Both reads and writes 404. So the two
BDEFs have to be pasted in Eclipse.

The behaviour pool's Local Types include (`ZBP_I_QC_INSP_LOT` CCIMP) is a
sub-object the tool does not address either - `objectType CLAS` reaches the
main source only.

## Backend complete, 28 Aug 2026

Verified against the live OData metadata at
`/sap/opu/odata4/sap/zui_qc_inspection_04/srvd/sap/zui_qc_inspection/0001/$metadata`:

- Six actions exposed: `recordSingleResult`, `recordResults`,
  `setUsageDecision`, `releaseToProduction`, `confirmDyeing`, `confirmWinding`.
- `__OperationControl` carries all six as properties, so instance feature
  control reaches the client for every one of them.
- `OrderBatch` entity set present. All order- and batch-level fields present
  on `InspectionLot`. Nothing inactive.

### What the BDEF episode cost, and why

Behaviour definitions cannot be read or written through this MCP server - it
addresses the old BOPF path `/sap/bc/adt/bopf/bdef/sources/` and 404s on both.
Full replacements were written for them anyway, from the stale repo copy, and
that copy was wrong in three ways the live object was right:

1. `lock master` and `authorization master ( global )` are **header clauses**
   between the `define behavior for` line and the opening brace, with no
   semicolons. Inside the braces they produce
   `"action | ancestor | association | changedocument..." was expected`.
   The live file already carried a comment saying this - it had been learned
   once and was erased.
2. Every action carries `( features : instance )`, including the three that
   already existed. The Detail view binds each footer button to
   `__OperationControl/<action>`; without instance feature control the property
   never reaches the service, the binding resolves to undefined, UI5 reads it
   as false and the button is dead. Dropping it would not have failed
   activation - it would have silently disabled Save, Record Results and Usage
   Decision.
3. There is no `association _Characteristic;`. ZI_QC_INSP_CHAR has no
   behaviour definition, and an association to a behaviourless entity does not
   activate.

**Rule for next time: never write a full replacement for an object that cannot
be read back.** Insert-only, against the live text.

## Remaining

- **Plant 2002 QM master data.** Still the blocker for testing anything - no
  MICs, no plans, no ZQC-UD selected set, inspection type 89 on one material.
  See `masterdata/PLANT-2002-QM-SETUP.md`.
- **The three follow-on buttons do not exist in the apps yet.** The actions are
  live on the service; the Detail views need the buttons, bound to
  `__OperationControl/<action>` like the existing three.
- **`patch-save3.js` is still built and never deployed.** The Save round trip
  has still never completed end to end.
- `ZQC_CONF_BATCH` has no rows yet, by definition.
