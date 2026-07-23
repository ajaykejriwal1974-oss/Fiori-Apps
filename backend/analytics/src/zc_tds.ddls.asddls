@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'TDS (Withholding Tax) Register'
@Analytics.query: true
@Metadata.allowExtensions: true
define view entity ZC_TDS
  as select from ZI_TDS
{
      @AnalyticsDetails.query.axis: #ROWS
      CompanyCode,
      @AnalyticsDetails.query.axis: #ROWS
      WithholdingTaxType,
      @AnalyticsDetails.query.axis: #ROWS
      AccountingDocument,
      @AnalyticsDetails.query.axis: #FREE
      FiscalYear,
      @AnalyticsDetails.query.axis: #FREE
      LineItem,
      @AnalyticsDetails.query.axis: #FREE
      WithholdingTaxCode,
      @AnalyticsDetails.query.axis: #COLUMNS
      WithholdingBaseAmount,
      @AnalyticsDetails.query.axis: #COLUMNS
      WithholdingTaxAmount,
      @AnalyticsDetails.query.axis: #COLUMNS
      RecordCount
}
