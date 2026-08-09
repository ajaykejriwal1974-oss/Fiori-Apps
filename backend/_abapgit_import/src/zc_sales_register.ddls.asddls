@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Sales Register'
@Analytics.query: true
@Metadata.allowExtensions: true
define view entity ZC_SALES_REGISTER
  as select from ZI_SALES_REGISTER
{
      @AnalyticsDetails.query.axis: #ROWS
      @Consumption.valueHelpDefinition: [ { entity: { name: 'ZI_VH_COMPANYCODE', element: 'CompanyCode' } } ]
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
      @Consumption.valueHelpDefinition: [ { entity: { name: 'ZI_VH_SALESORG', element: 'SalesOrganization' } } ]
      SalesOrganization,
      @AnalyticsDetails.query.axis: #FREE
      @Consumption.valueHelpDefinition: [ { entity: { name: 'I_Customer', element: 'Customer' } } ]
      SoldToParty,
      @AnalyticsDetails.query.axis: #FREE
      @Consumption.valueHelpDefinition: [ { entity: { name: 'I_Customer', element: 'Customer' } } ]
      Payer,
      @AnalyticsDetails.query.axis: #FREE
      Cancelled,
      @AnalyticsDetails.query.axis: #FREE
      @Consumption.valueHelpDefinition: [ { entity: { name: 'I_Product', element: 'Product' } } ]
      Material,
      @AnalyticsDetails.query.axis: #FREE
      MaterialText,
      @AnalyticsDetails.query.axis: #FREE
      @Consumption.valueHelpDefinition: [ { entity: { name: 'ZI_VH_PLANT', element: 'Plant' } } ]
      Plant,
      @AnalyticsDetails.query.axis: #FREE
      @Consumption.valueHelpDefinition: [ { entity: { name: 'I_SalesOrder', element: 'SalesOrder' } } ]
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
