@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Credit/Debit Note Register'
@Analytics.query: true
@Metadata.allowExtensions: true
define view entity ZC_CRDR_NOTE
  as select from ZI_CRDR_NOTE
{
      @AnalyticsDetails.query.axis: #ROWS
      @Consumption.valueHelpDefinition: [ { entity: { name: 'I_CompanyCode', element: 'CompanyCode' } } ]
      CompanyCode,
      @AnalyticsDetails.query.axis: #ROWS
      AccountingDocument,
      @AnalyticsDetails.query.axis: #ROWS
      FiscalYear,
      @AnalyticsDetails.query.axis: #FREE
      LedgerGLLineItem,
      @AnalyticsDetails.query.axis: #FREE
      DocumentType,
      @AnalyticsDetails.query.axis: #FREE
      DebitCreditCode,
      @AnalyticsDetails.query.axis: #FREE
      PostingDate,
      @AnalyticsDetails.query.axis: #FREE
      DocumentDate,
      @AnalyticsDetails.query.axis: #FREE
      GLAccount,
      @AnalyticsDetails.query.axis: #FREE
      @Consumption.valueHelpDefinition: [ { entity: { name: 'I_Customer', element: 'Customer' } } ]
      Customer,
      @AnalyticsDetails.query.axis: #FREE
      @Consumption.valueHelpDefinition: [ { entity: { name: 'I_Supplier', element: 'Supplier' } } ]
      Supplier,
      @AnalyticsDetails.query.axis: #FREE
      CompanyCodeCurrency,
      @AnalyticsDetails.query.axis: #COLUMNS
      AmountInCoCodeCrcy,
      @AnalyticsDetails.query.axis: #COLUMNS
      RecordCount
}
