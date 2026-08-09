@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'WIP Batch'
@Analytics.query: true
@Metadata.allowExtensions: true
define view entity ZC_WIP_BATCH
  as select from ZI_WIP_BATCH
{
      @AnalyticsDetails.query.axis: #ROWS
      Batch,
      @AnalyticsDetails.query.axis: #ROWS
      FiscalYear,
      @AnalyticsDetails.query.axis: #ROWS
      @Consumption.valueHelpDefinition: [ { entity: { name: 'I_Plant', element: 'Plant' } } ]
      Plant,
      @AnalyticsDetails.query.axis: #FREE
      ProductionOrder,
      @AnalyticsDetails.query.axis: #FREE
      BatchDate,
      @AnalyticsDetails.query.axis: #FREE
      @Consumption.valueHelpDefinition: [ { entity: { name: 'I_Product', element: 'Product' } } ]
      GreyMaterial,
      @AnalyticsDetails.query.axis: #FREE
      @Consumption.valueHelpDefinition: [ { entity: { name: 'I_Product', element: 'Product' } } ]
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
