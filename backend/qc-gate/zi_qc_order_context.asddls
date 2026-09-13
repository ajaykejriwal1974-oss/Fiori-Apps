// !! STALE AS OF 2026-08-28 - DO NOT PASTE THIS BACK INTO SAP !!
//
// This copy predates the LOTNO refactor and still uses field names that no
// longer exist (GreigeLot on ZI_QC_BATCH_JOB, GreigeLotCount on
// ZI_QC_ORDER_CONTEXT). Activating it would undo the fix and break the three
// QC apps, whose $select statements now read GreigeLotRef.
//
// The active version in KSD is the source of truth - read it with ADT rather
// than trusting this file. What changed and why: CHANGE-2026-08-28-lotno.md
//
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'QC: order-level totals'
// One row per (plant, production order), and deliberately NARROW.
//
// An order is created with a big quantity and then split into many small
// batches - order 000001008695 carries six, 000001008704 six, 000001008691
// five. So most facts about an order are not single-valued: greige lot, job
// card, work centre and batch number all vary batch by batch and belong at
// batch level, not here. Rolling them up with MAX would show one batch's data
// under the order's name, which is precisely the variation QC exists to catch.
//
// What is left is what an order genuinely has one of - the greige material
// going in and the dyed material coming out, both constant across an order's
// batches - plus honest totals and counts. The *Count fields audit the two MAX
// fields: GreigeMaterialCount above 1 means the order draws on more than one
// greige material and GreigeMaterial is only the highest of them.
//
// GreigeLotCount earns its place: order 000001008695 runs greige lot TEST1 on
// two batches and 3254-TEST on four. The greige lot is NOT an order-level fact.
//
// There is no OrderUnit, and that is deliberate rather than an omission. A
// UNIT field can be neither aggregated nor cast, so the only ways to carry one
// here would be to group by it - which splits an order into two rows the day
// its batches ever disagree - or to invent one. The quantity is therefore a
// plain number at order level, and the real unit stays on the batch, where it
// is single-valued. It is blank on every 2026 batch in any case.
define view entity ZI_QC_ORDER_CONTEXT
  as select from ZI_QC_BATCH_JOB
{
  key Plant,
  key ProductionOrder,
      max( GreigeMaterial )            as GreigeMaterial,
      count( distinct GreigeMaterial ) as GreigeMaterialCount,
      max( DyedMaterial )              as DyedMaterial,
      count( distinct DyedMaterial )   as DyedMaterialCount,
      count( distinct GreigeLot )      as GreigeLotCount,
      sum( cast( BatchQuantity as abap.dec(15,3) ) ) as OrderQuantity,
      sum( Cheeses )                   as OrderCheeses,
      count( * )                       as BatchCount,
      sum( case BatchClosed when 'X' then 0 else 1 end ) as OpenBatchCount,
      min( BatchDate )                 as FirstBatchDate,
      max( BatchDate )                 as LastBatchDate
}
where ProductionOrder <> ' '
group by Plant,
         ProductionOrder
