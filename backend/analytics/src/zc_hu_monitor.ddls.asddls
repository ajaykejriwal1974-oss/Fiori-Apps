@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'HU Monitor / Reconciliation'
@Analytics.query: true
@Metadata.allowExtensions: true
// Second query over ZI_HuInventoryCube (one cube, many queries). The monitor /
// reconciliation perspective (replaces ZHUMO, ZHUREC): leads with storage
// location + status so HUs are grouped by where they sit and their count state,
// vs. ZC_HuInventoryQuery which leads with the phys.-inv. document.
define view entity ZC_HuMonitorQuery
  as projection on ZI_HuInventoryCube
{
      @AnalyticsDetails.query.axis: #ROWS
      StorageLocation,
      @AnalyticsDetails.query.axis: #ROWS
      Status,
      @AnalyticsDetails.query.axis: #ROWS
      HandlingUnit,
      @AnalyticsDetails.query.axis: #FREE
      Material,
      @AnalyticsDetails.query.axis: #FREE
      Batch,
      @AnalyticsDetails.query.axis: #FREE
      PackagingMaterial,
      @AnalyticsDetails.query.axis: #FREE
      PhysInvDocument,
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
