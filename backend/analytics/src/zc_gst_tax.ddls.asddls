@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'GST Tax Register'
@Analytics.query: true
@Metadata.allowExtensions: true
define view entity ZC_GstTaxQuery
  as projection on ZI_GstTaxCube
{
      @AnalyticsDetails.query.axis: #ROWS
      Plant,
      @AnalyticsDetails.query.axis: #ROWS
      Vendor,
      @AnalyticsDetails.query.axis: #ROWS
      BillToParty,
      @AnalyticsDetails.query.axis: #FREE
      PlantState,
      @AnalyticsDetails.query.axis: #FREE
      VendorState,
      @AnalyticsDetails.query.axis: #FREE
      ShipToParty,
      @AnalyticsDetails.query.axis: #FREE
      ShipToState,
      @AnalyticsDetails.query.axis: #FREE
      BillToState,
      @AnalyticsDetails.query.axis: #COLUMNS
      RecordCount
}
