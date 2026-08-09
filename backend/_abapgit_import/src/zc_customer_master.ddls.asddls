@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Customer Register'
@Analytics.query: true
@Metadata.allowExtensions: true
define view entity ZC_CUSTOMER_MASTER
  as select from ZI_CUSTOMER_MASTER
{
      @AnalyticsDetails.query.axis: #ROWS
      @Consumption.valueHelpDefinition: [ { entity: { name: 'I_Customer', element: 'Customer' } } ]
      Customer,
      @AnalyticsDetails.query.axis: #ROWS
      CustomerName,
      @AnalyticsDetails.query.axis: #FREE
      @Consumption.valueHelpDefinition: [ { entity: { name: 'ZI_VH_SALESORG', element: 'SalesOrganization' } } ]
      SalesOrg,
      @AnalyticsDetails.query.axis: #FREE
      @Consumption.valueHelpDefinition: [ { entity: { name: 'ZI_VH_DISTCHANNEL', element: 'DistributionChannel' } } ]
      DistributionChannel,
      @AnalyticsDetails.query.axis: #FREE
      @Consumption.valueHelpDefinition: [ { entity: { name: 'ZI_VH_DIVISION', element: 'Division' } } ]
      Division,
      @AnalyticsDetails.query.axis: #FREE
      City,
      @AnalyticsDetails.query.axis: #FREE
      GSTIN,
      @AnalyticsDetails.query.axis: #FREE
      PANNumber,
      @AnalyticsDetails.query.axis: #FREE
      SalesAgentName,
      @AnalyticsDetails.query.axis: #FREE
      SalesPaymentTerms,
      @AnalyticsDetails.query.axis: #FREE
      CustomerName2,
      @AnalyticsDetails.query.axis: #FREE
      SearchTerm,
      @AnalyticsDetails.query.axis: #FREE
      Street,
      @AnalyticsDetails.query.axis: #FREE
      PostalCode,
      @AnalyticsDetails.query.axis: #FREE
      District,
      @AnalyticsDetails.query.axis: #FREE
      CSTNumber,
      @AnalyticsDetails.query.axis: #FREE
      LSTNumber,
      @AnalyticsDetails.query.axis: #FREE
      CreatedOn,
      @AnalyticsDetails.query.axis: #COLUMNS
      @DefaultAggregation: #SUM
      RecordCount
}
