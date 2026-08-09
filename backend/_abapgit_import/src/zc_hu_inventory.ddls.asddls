@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'HU Inventory Analysis'
@Analytics.query: true
@Metadata.allowExtensions: true
define view entity ZC_HU_INVENTORY
  as select from ZI_HU_INVENTORY
{
      @AnalyticsDetails.query.axis: #ROWS
      PhysInvDocument,
      @AnalyticsDetails.query.axis: #ROWS
      HandlingUnit,
      @AnalyticsDetails.query.axis: #ROWS
      @Consumption.valueHelpDefinition: [ { entity: { name: 'I_Product', element: 'Product' } } ]
      Material,
      @AnalyticsDetails.query.axis: #FREE
      Batch,
      @AnalyticsDetails.query.axis: #FREE
      StorageLocation,
      @AnalyticsDetails.query.axis: #FREE
      @Consumption.valueHelpDefinition: [ { entity: { name: 'I_Product', element: 'Product' } } ]
      PackagingMaterial,
      @AnalyticsDetails.query.axis: #FREE
      Status,
      @AnalyticsDetails.query.axis: #FREE
      CountedBy,
      @AnalyticsDetails.query.axis: #FREE
      CountDate,
      BaseUnit,
      @AnalyticsDetails.query.axis: #COLUMNS
      CountedQuantity,
      @AnalyticsDetails.query.axis: #COLUMNS
      RecordCount
}
