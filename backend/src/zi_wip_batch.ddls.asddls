@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'WIP Batch - Cube'
@Analytics: { dataCategory: #CUBE, dataExtraction.enabled: true }
@Metadata.allowExtensions: true
// Analytical cube over ZPP_BATCHN. Replaces: ZBATCH_WIP.
// Old report variants are now dimensions; aggregate in the query.
//
// Deleted batches are excluded. This view had no DELIND filter, so the totals
// counted 91 deleted batches - 43,907.630 kg and 22,425 cheeses - alongside the
// 131,502 live ones (measured 2026-08-30). An analytical cube that quietly adds
// deleted rows to a quantity is worse than one that is missing, because nobody
// questions a number that looks plausible.
//
// Labels are set here rather than left to the data element. GreyMaterial and
// DyedMaterial both resolve to MATNR, so the query browser listed two dimensions
// called "Material" with no way to tell them apart; Assigned and Closed came
// through as "Assignment" and "batch close ind.".
define view entity ZI_WIP_BATCH
  as select from zpp_batchn
{
      @EndUserText.label: 'Batch'
  key batchno          as Batch,
      @EndUserText.label: 'Fiscal Year'
  key gjahr            as FiscalYear,
      @EndUserText.label: 'Plant'
      werks            as Plant,
      @EndUserText.label: 'Production Order'
      aufnr            as ProductionOrder,
      @EndUserText.label: 'Batch Date'
      bchdate          as BatchDate,
      @EndUserText.label: 'Greige Material'
      grey_code        as GreyMaterial,
      @EndUserText.label: 'Dyed Material'
      dye_code         as DyedMaterial,
      @EndUserText.label: 'Assigned to Job Card'
      assigned         as Assigned,
      @EndUserText.label: 'Closed'
      closed           as Closed,
      @EndUserText.label: 'Quantity'
      @DefaultAggregation: #SUM
      cast( qty as abap.dec( 15, 3 ) ) as Quantity,
      @EndUserText.label: 'Unit'
      vrkme            as BatchUnit,
      @EndUserText.label: 'Cheeses'
      @DefaultAggregation: #SUM
      cast( cheeses as abap.dec( 15, 3 ) ) as Cheeses,
      @DefaultAggregation: #SUM
      @EndUserText.label: 'Record Count'
      cast( 1 as abap.int4 ) as RecordCount
}
where
  delind <> 'X'
