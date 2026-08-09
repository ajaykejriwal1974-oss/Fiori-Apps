@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Job-Work Challan Register'
@Analytics.query: true
@Metadata.allowExtensions: true
define view entity ZC_JOBWORK_CHALLAN
  as select from ZI_JOBWORK_CHALLAN
{
      @AnalyticsDetails.query.axis: #ROWS
      @Consumption.valueHelpDefinition: [ { entity: { name: 'I_Plant', element: 'Plant' } } ]
      Plant,
      @AnalyticsDetails.query.axis: #ROWS
      MaterialDocument,
      @AnalyticsDetails.query.axis: #ROWS
      MaterialDocItem,
      @AnalyticsDetails.query.axis: #FREE
      MaterialDocYear,
      @AnalyticsDetails.query.axis: #FREE
      @Consumption.valueHelpDefinition: [ { entity: { name: 'I_OutboundDelivery', element: 'OutboundDelivery' } } ]
      OutboundDelivery,
      @AnalyticsDetails.query.axis: #FREE
      MovementType,
      @AnalyticsDetails.query.axis: #FREE
      @Consumption.valueHelpDefinition: [ { entity: { name: 'I_Product', element: 'Product' } } ]
      Material,
      @AnalyticsDetails.query.axis: #FREE
      StorageLocation,
      @AnalyticsDetails.query.axis: #FREE
      @Consumption.valueHelpDefinition: [ { entity: { name: 'I_Supplier', element: 'Supplier' } } ]
      Supplier,
      @AnalyticsDetails.query.axis: #FREE
      PostingDate,
      @AnalyticsDetails.query.axis: #FREE
      BaseUnit,
      @AnalyticsDetails.query.axis: #COLUMNS
      Quantity,
      @AnalyticsDetails.query.axis: #COLUMNS
      RecordCount
}
