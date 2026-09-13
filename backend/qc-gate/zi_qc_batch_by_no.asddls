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
@EndUserText.label: 'QC: plant batch by number alone'
// ZPP_BATCHN is keyed on BATCHNO + GJAHR, so a batch number on its own is not
// unique across years. This view collapses that to one row per (plant, batch
// number) taking the latest year, which is what lets an inspection lot resolve
// its batch from QALS-CHARG without a fiscal year to hand.
//
// YearCount above 1 means the same batch number has been used in more than one
// year and the caller is looking at the most recent - worth knowing before a
// confirmation is posted against it.
define view entity ZI_QC_BATCH_BY_NO
  as select from ZI_QC_BATCH_JOB
{
  key Plant,
  key BatchNumber,
      max( FiscalYear )      as FiscalYear,
      max( ProductionOrder ) as ProductionOrder,
      max( JobCard )         as JobCard,
      max( GreigeLot )       as GreigeLot,
      count( * )             as YearCount
}
group by Plant,
         BatchNumber
