@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Job-Work Challan Register'
@Analytics.query: true
@Metadata.allowExtensions: true
define view entity ZC_JOBWORK_CHALLAN
  as select from ZI_JOBWORK_CHALLAN
{
      @AnalyticsDetails.query.axis: #ROWS
      Plant,
      @AnalyticsDetails.query.axis: #ROWS
      MaterialDocument,
      @AnalyticsDetails.query.axis: #ROWS
      MaterialDocItem,
      @AnalyticsDetails.query.axis: #FREE
      MaterialDocYear,
      @AnalyticsDetails.query.axis: #FREE
      OutboundDelivery,
      @AnalyticsDetails.query.axis: #FREE
      MovementType,
      @AnalyticsDetails.query.axis: #FREE
      Material,
      @AnalyticsDetails.query.axis: #FREE
      StorageLocation,
      @AnalyticsDetails.query.axis: #FREE
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
