@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Sales Register'
@Analytics.query: true
@Metadata.allowExtensions: true
define view entity ZC_SALES_REGISTER
  as select from ZI_SALES_REGISTER
{
      @AnalyticsDetails.query.axis: #ROWS
      CompanyCode,
      @AnalyticsDetails.query.axis: #ROWS
      BillingDocument,
      @AnalyticsDetails.query.axis: #ROWS
      BillingItem,
      @AnalyticsDetails.query.axis: #FREE
      BillingType,
      @AnalyticsDetails.query.axis: #FREE
      BillingDate,
      @AnalyticsDetails.query.axis: #FREE
      SalesOrganization,
      @AnalyticsDetails.query.axis: #FREE
      SoldToParty,
      @AnalyticsDetails.query.axis: #FREE
      Payer,
      @AnalyticsDetails.query.axis: #FREE
      Cancelled,
      @AnalyticsDetails.query.axis: #FREE
      Material,
      @AnalyticsDetails.query.axis: #FREE
      MaterialText,
      @AnalyticsDetails.query.axis: #FREE
      Plant,
      @AnalyticsDetails.query.axis: #FREE
      SalesOrder,
      @AnalyticsDetails.query.axis: #FREE
      SalesUnit,
      @AnalyticsDetails.query.axis: #FREE
      Currency,
      @AnalyticsDetails.query.axis: #COLUMNS
      BilledQuantity,
      @AnalyticsDetails.query.axis: #COLUMNS
      NetValue,
      @AnalyticsDetails.query.axis: #COLUMNS
      TaxAmount,
      @AnalyticsDetails.query.axis: #COLUMNS
      RecordCount
}
