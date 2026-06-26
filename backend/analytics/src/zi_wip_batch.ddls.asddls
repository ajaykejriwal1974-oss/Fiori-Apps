@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'WIP Batch - Cube'
@Analytics: { dataCategory: #CUBE, dataExtraction.enabled: true }
@Metadata.allowExtensions: true
// Analytical cube over ZPP_BATCHN. Replaces: ZBATCH_WIP.
// Old report variants are now dimensions; aggregate in the query.
define view entity ZI_WipBatchCube
  as select from zpp_batchn
{
  key batchno          as Batch,
  key gjahr            as FiscalYear,
      werks            as Plant,
      aufnr            as Order,
      bchdate          as BatchDate,
      grey_code        as GreyMaterial,
      dye_code         as DyedMaterial,
      assigned         as Assigned,
      closed           as Closed,
      @DefaultAggregation: #SUM
      @Semantics.quantity.unitOfMeasure: 'BatchUnit'
      qty              as Quantity,
      @Semantics.unitOfMeasure: true
      vrkme            as BatchUnit,
      @DefaultAggregation: #SUM
      cheeses          as Cheeses,
      @DefaultAggregation: #SUM
      @EndUserText.label: 'Record Count'
      cast( 1 as abap.int4 ) as RecordCount
}
