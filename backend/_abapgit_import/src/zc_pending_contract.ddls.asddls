@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Pending Contract Register'
@Analytics.query: true
@Metadata.allowExtensions: true
define view entity ZC_PENDING_CONTRACT
  as select from ZI_PENDING_CONTRACT
{
      @AnalyticsDetails.query.axis: #ROWS
      ScheduleNumber,
      @AnalyticsDetails.query.axis: #ROWS
      FiscalYear,
      @AnalyticsDetails.query.axis: #ROWS
      @Consumption.valueHelpDefinition: [ { entity: { name: 'I_Plant', element: 'Plant' } } ]
      Plant,
      @AnalyticsDetails.query.axis: #FREE
      @Consumption.valueHelpDefinition: [ { entity: { name: 'I_SalesOrderStdVH', element: 'SalesOrder' } } ]
      SalesDocument,
      @AnalyticsDetails.query.axis: #FREE
      SalesItem,
      @AnalyticsDetails.query.axis: #FREE
      @Consumption.valueHelpDefinition: [ { entity: { name: 'I_Product', element: 'Product' } } ]
      Material,
      @AnalyticsDetails.query.axis: #FREE
      ShadeCode,
      @AnalyticsDetails.query.axis: #FREE
      Complete,
      @AnalyticsDetails.query.axis: #FREE
      DeletionFlag,
      @AnalyticsDetails.query.axis: #FREE
      @Consumption.filter: { selectionType: #INTERVAL, multipleSelections: false }
      ScheduleDate,
      @AnalyticsDetails.query.axis: #FREE
      @Consumption.filter: { selectionType: #INTERVAL, multipleSelections: false }
      DyeingDate,
      SalesUnit,
      @AnalyticsDetails.query.axis: #COLUMNS
      ScheduleQuantity,
      @AnalyticsDetails.query.axis: #COLUMNS
      RecordCount
}
