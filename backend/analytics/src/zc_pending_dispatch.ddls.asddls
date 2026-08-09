@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Pending / Security Dispatch'
@Analytics.query: true
@Metadata.allowExtensions: true
// Second query over ZI_DispatchRegisterCube (one cube, many queries). The
// pending / security-gate perspective (replaces ZPDESP pending, ZDISPATCH
// security): leads with status + date so open vs. dispatched boxes are grouped
// for the gate, vs. ZC_DispatchRegisterQuery which is the box-level register.
define view entity ZC_PendingDispatchQuery
  as projection on ZI_DispatchRegisterCube
{
      @AnalyticsDetails.query.axis: #ROWS
      Status,
      @AnalyticsDetails.query.axis: #ROWS
      DispatchDate,
      @AnalyticsDetails.query.axis: #ROWS
      SalesOrder,
      @AnalyticsDetails.query.axis: #FREE
      SalesOrderItem,
      @AnalyticsDetails.query.axis: #FREE
      PackListItem,
      @AnalyticsDetails.query.axis: #FREE
      Box,
      @AnalyticsDetails.query.axis: #COLUMNS
      RecordCount
}
