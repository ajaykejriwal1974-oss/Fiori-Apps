@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'GST Tax Register'
@Analytics.query: true
@Metadata.allowExtensions: true
define view entity ZC_GST_TAX
  as select from ZI_GST_TAX
{
      @AnalyticsDetails.query.axis: #ROWS
      CompanyCode,
      @AnalyticsDetails.query.axis: #ROWS
      BillingDocument,
      @AnalyticsDetails.query.axis: #ROWS
      BusinessPlace,
      @AnalyticsDetails.query.axis: #FREE
      SalesOrg,
      @AnalyticsDetails.query.axis: #FREE
      BillingType,
      @AnalyticsDetails.query.axis: #FREE
      Region,
      @AnalyticsDetails.query.axis: #FREE
      SoldToParty,
      @AnalyticsDetails.query.axis: #FREE
      Payer,
      @AnalyticsDetails.query.axis: #FREE
      VatRegistration,
      @AnalyticsDetails.query.axis: #FREE
      BillingDate,
      @AnalyticsDetails.query.axis: #FREE
      Cancelled,
      @AnalyticsDetails.query.axis: #FREE
      SalesDocument,
      @AnalyticsDetails.query.axis: #FREE
      Currency,
      @AnalyticsDetails.query.axis: #COLUMNS
      NetValue,
      @AnalyticsDetails.query.axis: #COLUMNS
      TaxAmount,
      @AnalyticsDetails.query.axis: #COLUMNS
      RecordCount
}
