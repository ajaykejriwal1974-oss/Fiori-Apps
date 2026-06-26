@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Dispatch Register'
@Analytics.query: true
@Metadata.allowExtensions: true
define view entity ZC_DispatchRegisterQuery
  as projection on ZI_DispatchRegisterCube
{
      @AnalyticsDetails.query.axis: #ROWS
      Box,
      @AnalyticsDetails.query.axis: #ROWS
      SalesOrder,
      @AnalyticsDetails.query.axis: #ROWS
      SalesOrderItem,
      @AnalyticsDetails.query.axis: #FREE
      PackListItem,
      @AnalyticsDetails.query.axis: #FREE
      Status,
      @AnalyticsDetails.query.axis: #FREE
      DispatchDate,
      @AnalyticsDetails.query.axis: #COLUMNS
      RecordCount
}
