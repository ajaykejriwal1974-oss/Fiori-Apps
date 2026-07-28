@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Gate Pass Register'
@Analytics.query: true
@Metadata.allowExtensions: true
// Consumption query for the gate-pass register. One query covers all the legacy
// gate-pass report variants: filter/drill by GatePassType (returnable /
// non-returnable / inward / outward) instead of a separate program per variant.
define view entity ZC_GATEPASS_REGISTER
  as select from ZI_GATEPASS_REGISTER
{
      @AnalyticsDetails.query.axis: #ROWS
      GatePassType,
      @AnalyticsDetails.query.axis: #ROWS
      Plant,
      @AnalyticsDetails.query.axis: #ROWS
      Department,
      @AnalyticsDetails.query.axis: #ROWS
      GatePassNumber,
      @AnalyticsDetails.query.axis: #ROWS
      GatePassYear,
      GatePassItem,
      VehicleNumber,
      GateInDate,
      GateOutDate,
      Material,
      MaterialDescription,
      Supplier,
      SupplierName,
      GatePassUnit,
      CreatedByUser,
      CreatedOn,
      @AnalyticsDetails.query.axis: #COLUMNS
      GatePassQuantity,
      @AnalyticsDetails.query.axis: #COLUMNS
      RecordCount
}
