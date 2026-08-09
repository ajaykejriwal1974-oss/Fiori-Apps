@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'HU Inventory Analysis'
@Analytics.query: true
@Metadata.allowExtensions: true
define view entity ZC_HuInventoryQuery
  as projection on ZI_HuInventoryCube
{
      @AnalyticsDetails.query.axis: #ROWS
      PhysInvDocument,
      @AnalyticsDetails.query.axis: #ROWS
      HandlingUnit,
      @AnalyticsDetails.query.axis: #ROWS
      Material,
      @AnalyticsDetails.query.axis: #FREE
      Batch,
      @AnalyticsDetails.query.axis: #FREE
      StorageLocation,
      @AnalyticsDetails.query.axis: #FREE
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
