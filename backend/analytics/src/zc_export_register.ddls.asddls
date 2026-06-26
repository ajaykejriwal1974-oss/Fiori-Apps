@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Export / Incentive Register'
@Analytics.query: true
@Metadata.allowExtensions: true
define view entity ZC_ExportRegisterQuery
  as projection on ZI_ExportRegisterCube
{
      @AnalyticsDetails.query.axis: #ROWS
      BillingDocument,
      @AnalyticsDetails.query.axis: #ROWS
      ConditionType,
      @AnalyticsDetails.query.axis: #ROWS
      BillingDate,
      Currency,
      @AnalyticsDetails.query.axis: #COLUMNS
      ExchangeRate,
      @AnalyticsDetails.query.axis: #COLUMNS
      NetValue,
      @AnalyticsDetails.query.axis: #COLUMNS
      RecordCount
}
