@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'E-Invoice/E-Way Audit Log'
@Analytics.query: true
@Metadata.allowExtensions: true
define view entity ZC_AUDIT_LOG
  as select from ZI_AUDIT_LOG
{
      @AnalyticsDetails.query.axis: #ROWS
      @Consumption.valueHelpDefinition: [ { entity: { name: 'I_CompanyCode', element: 'CompanyCode' } } ]
      CompanyCode,
      @AnalyticsDetails.query.axis: #ROWS
      BusinessPlace,
      @AnalyticsDetails.query.axis: #ROWS
      BillingDocument,
      @AnalyticsDetails.query.axis: #FREE
      IRNStatus,
      @AnalyticsDetails.query.axis: #FREE
      IRN,
      @AnalyticsDetails.query.axis: #FREE
      EWayBillNumber,
      @AnalyticsDetails.query.axis: #FREE
      @Consumption.filter: { selectionType: #INTERVAL, multipleSelections: false }
      DocumentDate,
      @AnalyticsDetails.query.axis: #FREE
      OfficialDocNumber,
      @AnalyticsDetails.query.axis: #FREE
      @Consumption.filter: { selectionType: #INTERVAL, multipleSelections: false }
      OfficialDocDate,
      @AnalyticsDetails.query.axis: #FREE
      SellerGSTIN,
      @AnalyticsDetails.query.axis: #FREE
      ExtractedOn,
      @AnalyticsDetails.query.axis: #FREE
      ExtractedBy,
      @AnalyticsDetails.query.axis: #FREE
      CancelledOn,
      @AnalyticsDetails.query.axis: #FREE
      CancelledBy,
      @AnalyticsDetails.query.axis: #FREE
      CancellationReason,
      @AnalyticsDetails.query.axis: #COLUMNS
      RecordCount
}
