@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Dispatch Register'
@Analytics.query: true
@Metadata.allowExtensions: true
define view entity ZC_DISPATCH_REGISTER
  as select from ZI_DISPATCH_REGISTER
{
      @AnalyticsDetails.query.axis: #ROWS
      Box,
      @AnalyticsDetails.query.axis: #ROWS
      @Consumption.valueHelpDefinition: [ { entity: { name: 'I_SalesOrderStdVH', element: 'SalesOrder' } } ]
      SalesOrder,
      @AnalyticsDetails.query.axis: #ROWS
      SalesOrderItem,
      @AnalyticsDetails.query.axis: #FREE
      PackListItem,
      @AnalyticsDetails.query.axis: #FREE
      Status,
      @AnalyticsDetails.query.axis: #FREE
      @Consumption.filter: { selectionType: #INTERVAL, multipleSelections: false }
      DispatchDate,
      @AnalyticsDetails.query.axis: #COLUMNS
      RecordCount
}
