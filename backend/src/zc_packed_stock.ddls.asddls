@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Packed-Stock Analysis'
@Analytics.query: true
@Metadata.allowExtensions: true
define view entity ZC_PACKED_STOCK
  as select from ZI_PACKED_STOCK
{
      @AnalyticsDetails.query.axis: #ROWS
      Box,
      @AnalyticsDetails.query.axis: #ROWS
      FiscalYear,
      @AnalyticsDetails.query.axis: #ROWS
      @Consumption.valueHelpDefinition: [ { entity: { name: 'I_Plant', element: 'Plant' } } ]
      Plant,
      @AnalyticsDetails.query.axis: #FREE
      StorageLocation,
      @AnalyticsDetails.query.axis: #FREE
      @Consumption.valueHelpDefinition: [ { entity: { name: 'I_Product', element: 'Product' } } ]
      Material,
      @AnalyticsDetails.query.axis: #FREE
      Grade,
      @AnalyticsDetails.query.axis: #FREE
      EndUse,
      @AnalyticsDetails.query.axis: #FREE
      PackingType,
      @AnalyticsDetails.query.axis: #FREE
      PackingSize,
      @AnalyticsDetails.query.axis: #FREE
      MergeNumber,
      @AnalyticsDetails.query.axis: #FREE
      WorkCenter,
      @AnalyticsDetails.query.axis: #FREE
      ProductType,
      // ZBOXSTOCK selection fields - the dispatch desk filters stock by these
      @AnalyticsDetails.query.axis: #FREE
      Denier,
      @AnalyticsDetails.query.axis: #FREE
      Filament,
      @AnalyticsDetails.query.axis: #FREE
      MaterialProductType,
      @AnalyticsDetails.query.axis: #FREE
      @Consumption.filter: { selectionType: #INTERVAL, multipleSelections: false }
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
