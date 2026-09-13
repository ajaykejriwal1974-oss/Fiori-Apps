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
@EndUserText.label: 'QC: order behind a greige lot'
// The bridge that lets a greige inspection lot find its order.
//
// A greige lot is raised on a goods receipt, so QALS-AUFNR is blank - the only
// handle it has is QALS-CHARG, the greige lot number. ZPP_BATCHN-LOTNO holds
// that same number and ZPP_BATCHN-AUFNR the dyeing order it has been assigned
// to, so this view turns a greige lot into an order.
//
// BatchCount above 1 means the greige lot has been split across more than one
// batch - the normal case here, since orders are big and batches are small.
// The resolved batch is therefore only indicative; Grey QC anchors on the
// order, which is single-valued, and never on this batch.
define view entity ZI_QC_BATCH_BY_GREIGE
  as select from ZI_QC_BATCH_JOB
{
  key Plant,
  key GreigeLot,
      max( ProductionOrder ) as ProductionOrder,
      max( BatchNumber )     as PlantBatch,
      max( FiscalYear )      as PlantBatchYear,
      max( JobCard )         as JobCard,
      count( * )             as BatchCount
}
where GreigeLot <> ' '
group by Plant,
         GreigeLot
