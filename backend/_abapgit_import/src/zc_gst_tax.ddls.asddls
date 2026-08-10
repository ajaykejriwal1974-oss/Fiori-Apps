@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'GST Tax Register'
@Analytics.query: true
@Metadata.allowExtensions: true
define view entity ZC_GST_TAX
  as select from ZI_GST_TAX
{
      @AnalyticsDetails.query.axis: #ROWS
      @Consumption.valueHelpDefinition: [ { entity: { name: 'ZI_VH_COMPANYCODE', element: 'CompanyCode' } } ]
      CompanyCode,
      @AnalyticsDetails.query.axis: #ROWS
      BillingDocument,
      @AnalyticsDetails.query.axis: #ROWS
      BusinessPlace,
      @AnalyticsDetails.query.axis: #FREE
      @Consumption.valueHelpDefinition: [ { entity: { name: 'ZI_VH_SALESORG', element: 'SalesOrganization' } } ]
      SalesOrg,
      @AnalyticsDetails.query.axis: #FREE
      @Consumption.valueHelpDefinition: [ { entity: { name: 'ZI_VH_BILLINGTYPE', element: 'BillingType' } } ]
      BillingType,
      @AnalyticsDetails.query.axis: #FREE
      Region,
      @AnalyticsDetails.query.axis: #FREE
      @Consumption.valueHelpDefinition: [ { entity: { name: 'I_Customer', element: 'Customer' } } ]
      SoldToParty,
      @AnalyticsDetails.query.axis: #FREE
      @Consumption.valueHelpDefinition: [ { entity: { name: 'I_Customer', element: 'Customer' } } ]
      Payer,
      @AnalyticsDetails.query.axis: #FREE
      VatRegistration,
      @AnalyticsDetails.query.axis: #FREE
      @Consumption.filter: { selectionType: #INTERVAL, multipleSelections: false }
      BillingDate,
      @AnalyticsDetails.query.axis: #FREE
      Cancelled,
      @AnalyticsDetails.query.axis: #FREE
      @Consumption.valueHelpDefinition: [ { entity: { name: 'I_SalesOrder', element: 'SalesOrder' } } ]
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
