@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Pending Contract Register'
@Analytics.query: true
@Metadata.allowExtensions: true
define view entity ZC_PendingContractQuery
  as projection on ZI_PendingContractCube
{
      @AnalyticsDetails.query.axis: #ROWS
      ScheduleNumber,
      @AnalyticsDetails.query.axis: #ROWS
      FiscalYear,
      @AnalyticsDetails.query.axis: #ROWS
      Plant,
      @AnalyticsDetails.query.axis: #FREE
      SalesDocument,
      @AnalyticsDetails.query.axis: #FREE
      SalesItem,
      @AnalyticsDetails.query.axis: #FREE
      Material,
      @AnalyticsDetails.query.axis: #FREE
      ShadeCode,
      @AnalyticsDetails.query.axis: #FREE
      Complete,
      @AnalyticsDetails.query.axis: #FREE
      DeletionFlag,
      @AnalyticsDetails.query.axis: #FREE
      ScheduleDate,
      @AnalyticsDetails.query.axis: #FREE
      DyeingDate,
      SalesUnit,
      @AnalyticsDetails.query.axis: #COLUMNS
      ScheduleQuantity,
      @AnalyticsDetails.query.axis: #COLUMNS
      RecordCount
}
