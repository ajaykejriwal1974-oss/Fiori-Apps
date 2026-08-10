@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Packing / Dispatch Register'
@Analytics.query: true
@Metadata.allowExtensions: true
define view entity ZC_PACKING_REGISTER
  as select from ZI_PACKED_STOCK
{
      @AnalyticsDetails.query.axis: #ROWS
      Box,
      @AnalyticsDetails.query.axis: #ROWS
      FiscalYear,
      @AnalyticsDetails.query.axis: #ROWS
      @Consumption.valueHelpDefinition: [ { entity: { name: 'I_SalesOrderStdVH', element: 'SalesOrder' } } ]
      SalesDocument,
      @AnalyticsDetails.query.axis: #FREE
      SalesItem,
      @AnalyticsDetails.query.axis: #FREE
      ProductionOrder,
      @AnalyticsDetails.query.axis: #FREE
      @Consumption.valueHelpDefinition: [ { entity: { name: 'I_Product', element: 'Product' } } ]
      Material,
      @AnalyticsDetails.query.axis: #FREE
      Grade,
      @AnalyticsDetails.query.axis: #FREE
      PackingType,
      @AnalyticsDetails.query.axis: #FREE
      PackingListFlag,
      @AnalyticsDetails.query.axis: #FREE
      Posted,
      @AnalyticsDetails.query.axis: #FREE
      @Consumption.filter: { selectionType: #INTERVAL, multipleSelections: false }
      PackingListDate,
      @AnalyticsDetails.query.axis: #COLUMNS
      NetWeight,
      @AnalyticsDetails.query.axis: #COLUMNS
      GrossWeight,
      @AnalyticsDetails.query.axis: #COLUMNS
      RecordCount
}
