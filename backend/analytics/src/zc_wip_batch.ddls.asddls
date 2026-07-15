@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'WIP Batch'
@Analytics.query: true
@Metadata.allowExtensions: true
define view entity ZC_WipBatchQuery
  as select from ZI_WipBatchCube
{
      @AnalyticsDetails.query.axis: #ROWS
      Batch,
      @AnalyticsDetails.query.axis: #ROWS
      FiscalYear,
      @AnalyticsDetails.query.axis: #ROWS
      Plant,
      @AnalyticsDetails.query.axis: #FREE
      ProductionOrder,
      @AnalyticsDetails.query.axis: #FREE
      BatchDate,
      @AnalyticsDetails.query.axis: #FREE
      GreyMaterial,
      @AnalyticsDetails.query.axis: #FREE
      DyedMaterial,
      @AnalyticsDetails.query.axis: #FREE
      Assigned,
      @AnalyticsDetails.query.axis: #FREE
      Closed,
      BatchUnit,
      @AnalyticsDetails.query.axis: #COLUMNS
      Quantity,
      @AnalyticsDetails.query.axis: #COLUMNS
      Cheeses,
      @AnalyticsDetails.query.axis: #COLUMNS
      RecordCount
}
