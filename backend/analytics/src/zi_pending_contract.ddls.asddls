@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Pending Contract Register - Cube'
@Analytics: { dataCategory: #CUBE, dataExtraction.enabled: true }
@Metadata.allowExtensions: true
// Analytical cube over ZPP_SCHEDULEN. Replaces: ZPCON, ZPCOND, ZPCONS (ZPCON_CP dropped).
// Old report variants are now dimensions; aggregate in the query.
define view entity ZI_PendingContractCube
  as select from zpp_schedulen
{
  key schno            as ScheduleNumber,
  key gjahr            as FiscalYear,
      werks            as Plant,
      vbeln            as SalesDocument,
      posnr            as SalesItem,
      matnr            as Material,
      shdcd            as ShadeCode,
      complete         as Complete,
      delind           as DeletionFlag,
      schdt            as ScheduleDate,
      dyedt            as DyeingDate,
      @DefaultAggregation: #SUM
      @Semantics.quantity.unitOfMeasure: 'SalesUnit'
      sch_qty          as ScheduleQuantity,
      @Semantics.unitOfMeasure: true
      vrkme            as SalesUnit,
      @DefaultAggregation: #SUM
      @EndUserText.label: 'Record Count'
      cast( 1 as abap.int4 ) as RecordCount
}
