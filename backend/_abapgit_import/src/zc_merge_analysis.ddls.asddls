@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Merge Analysis'
@Analytics.query: true
@Metadata.allowExtensions: true
define view entity ZC_MERGE_ANALYSIS
  as projection on ZI_MERGE_ANALYSIS
{
      @AnalyticsDetails.query.axis: #ROWS
      ProductionOrder,
      @AnalyticsDetails.query.axis: #ROWS
      Grade,
      @AnalyticsDetails.query.axis: #ROWS
      EndUse,
      @AnalyticsDetails.query.axis: #FREE
      Batch,
      @AnalyticsDetails.query.axis: #FREE
      ShadeCode,
      @AnalyticsDetails.query.axis: #COLUMNS
      Quantity,
      @AnalyticsDetails.query.axis: #COLUMNS
      RecordCount
}
