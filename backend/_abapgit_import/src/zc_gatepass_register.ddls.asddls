@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Gate Pass Register'
@Analytics.query: true
@Metadata.allowExtensions: true
define view entity ZC_GATEPASS_REGISTER
  as select from ZI_GATEPASS_REGISTER
{
      @AnalyticsDetails.query.axis: #ROWS
      GatePassType,
      @AnalyticsDetails.query.axis: #ROWS
      @Consumption.valueHelpDefinition: [ { entity: { name: 'I_Plant', element: 'Plant' } } ]
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
      @Consumption.valueHelpDefinition: [ { entity: { name: 'I_Product', element: 'Product' } } ]
      Material,
      MaterialDescription,
      @Consumption.valueHelpDefinition: [ { entity: { name: 'I_Supplier', element: 'Supplier' } } ]
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
