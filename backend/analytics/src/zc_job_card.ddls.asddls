@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Job Card Report'
@Analytics.query: true
@Metadata.allowExtensions: true
define view entity ZC_JobCardQuery
  as projection on ZI_JobCardCube
{
      @AnalyticsDetails.query.axis: #ROWS
      JobNumber,
      @AnalyticsDetails.query.axis: #ROWS
      Batch,
      @AnalyticsDetails.query.axis: #ROWS
      ScheduleNumber,
      @AnalyticsDetails.query.axis: #FREE
      Plant,
      @AnalyticsDetails.query.axis: #FREE
      DyeingWorkCenter,
      @AnalyticsDetails.query.axis: #FREE
      WindingWorkCenter,
      @AnalyticsDetails.query.axis: #FREE
      DeletionFlag,
      @AnalyticsDetails.query.axis: #COLUMNS
      RecordCount
}
