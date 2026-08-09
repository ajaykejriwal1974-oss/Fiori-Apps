@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Packing / Dispatch Register'
@Analytics.query: true
@Metadata.allowExtensions: true
define view entity ZC_PackingRegisterQuery
  as projection on ZI_PackedStockCube
{
      @AnalyticsDetails.query.axis: #ROWS
      Box,
      @AnalyticsDetails.query.axis: #ROWS
      FiscalYear,
      @AnalyticsDetails.query.axis: #ROWS
      SalesDocument,
      @AnalyticsDetails.query.axis: #FREE
      SalesItem,
      @AnalyticsDetails.query.axis: #FREE
      Order,
      @AnalyticsDetails.query.axis: #FREE
      Material,
      @AnalyticsDetails.query.axis: #FREE
      Grade,
      @AnalyticsDetails.query.axis: #FREE
      PackingType,
      @AnalyticsDetails.query.axis: #FREE
      PackingListFlag,
      @AnalyticsDetails.query.axis: #FREE
      Posted,
      @AnalyticsDetails.query.axis: #FREE
      PackingListDate,
      @AnalyticsDetails.query.axis: #COLUMNS
      NetWeight,
      @AnalyticsDetails.query.axis: #COLUMNS
      GrossWeight,
      @AnalyticsDetails.query.axis: #COLUMNS
      RecordCount
}
