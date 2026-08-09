@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Packed-Stock Analysis'
@Analytics.query: true
@Metadata.allowExtensions: true
define view entity ZC_PackedStockQuery
  as projection on ZI_PackedStockCube
{
      @AnalyticsDetails.query.axis: #ROWS
      Box,
      @AnalyticsDetails.query.axis: #ROWS
      FiscalYear,
      @AnalyticsDetails.query.axis: #ROWS
      Plant,
      @AnalyticsDetails.query.axis: #FREE
      StorageLocation,
      @AnalyticsDetails.query.axis: #FREE
      Material,
      @AnalyticsDetails.query.axis: #FREE
      Grade,
      @AnalyticsDetails.query.axis: #FREE
      EndUse,
      @AnalyticsDetails.query.axis: #FREE
      PackingType,
      @AnalyticsDetails.query.axis: #FREE
      Size,
      @AnalyticsDetails.query.axis: #FREE
      MergeNumber,
      @AnalyticsDetails.query.axis: #FREE
      WorkCenter,
      @AnalyticsDetails.query.axis: #FREE
      ProductType,
      @AnalyticsDetails.query.axis: #FREE
      PackingDate,
      @AnalyticsDetails.query.axis: #COLUMNS
      GrossWeight,
      @AnalyticsDetails.query.axis: #COLUMNS
      TareWeight,
      @AnalyticsDetails.query.axis: #COLUMNS
      NetWeight,
      @AnalyticsDetails.query.axis: #COLUMNS
      RecordCount
}
