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
@EndUserText.label: 'QC: plant batch with its job card'
// One row per plant batch (ZPP_BATCHN, key BATCHNO + GJAHR).
//
// ZPP_BATCHN is the record that ties a greige lot to a dyeing production
// order: LOTNO is the greige lot, GREY_CODE the greige material, DYE_CODE the
// dyed material it becomes, AUFNR the order. Everything the QC apps need about
// an order comes from here, rolled up in ZI_QC_ORDER_CONTEXT.
//
// The job card is reached through ZI_QC_JOB_BY_BATCH, which is already
// aggregated to one row per batch, and the job card attributes are then read
// back from ZPP_JOBN on its full key JOBNO. Neither join can multiply a batch.
define view entity ZI_QC_BATCH_JOB
  as select from zpp_batchn as batch
    left outer join ZI_QC_JOB_BY_BATCH as jb  on  jb.Plant       = batch.werks
                                              and jb.BatchNumber = batch.batchno
    left outer join zpp_jobn           as job on  job.jobno      = jb.JobCard
{
  key batch.batchno   as BatchNumber,
  key batch.gjahr     as FiscalYear,
      batch.werks     as Plant,
      batch.aufnr     as ProductionOrder,
      batch.bchdate   as BatchDate,
      batch.lotno     as GreigeLot,
      batch.grey_code as GreigeMaterial,
      batch.grey_item as GreigeItem,
      batch.dye_code  as DyedMaterial,
      batch.dye_item  as DyedItem,
      @Semantics.quantity.unitOfMeasure: 'BatchUnit'
      batch.qty       as BatchQuantity,
      batch.vrkme     as BatchUnit,
      // ZDE_CHEESES is typed QUAN, so CDS wants a unit reference for it. But a
      // cheese is a thing you count, not an amount you measure - pointing it at
      // BatchUnit would render 85 cheeses as "85 KG". Cast to a plain decimal
      // instead and let it be the count it is.
      cast( batch.cheeses as abap.dec(15,0) ) as Cheeses,
      batch.assigned  as BatchAssigned,
      batch.closed    as BatchClosed,
      batch.closed_by as BatchClosedBy,
      batch.closed_on as BatchClosedOn,
      jb.JobCard      as JobCard,
      jb.JobCardCount as JobCardCount,
      job.schno       as ScheduleNumber,
      job.dye_arbpl   as DyeingWorkCentre,
      job.win_arbpl   as WindingWorkCentre
}
where batch.delind = ' '
