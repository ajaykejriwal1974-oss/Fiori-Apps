@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Export / Incentive Register'
@Analytics.query: true
@Metadata.allowExtensions: true
define view entity ZC_EXPORT_REGISTER
  as projection on ZI_EXPORT_REGISTER
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
