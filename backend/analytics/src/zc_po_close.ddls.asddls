@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'PO Closure Register'
@Analytics.query: true
@Metadata.allowExtensions: true
define view entity ZC_PO_CLOSE
  as select from ZI_PO_CLOSE
{
      @AnalyticsDetails.query.axis: #ROWS
      @Consumption.valueHelpDefinition: [ { entity: { name: 'ZI_VH_COMPANYCODE', element: 'CompanyCode' } } ]
      CompanyCode,
      @AnalyticsDetails.query.axis: #ROWS
      PurchaseOrder,
      @AnalyticsDetails.query.axis: #ROWS
      PurchaseOrderItem,
      @AnalyticsDetails.query.axis: #FREE
      @Consumption.valueHelpDefinition: [ { entity: { name: 'I_Supplier', element: 'Supplier' } } ]
      Supplier,
      @AnalyticsDetails.query.axis: #FREE
      @Consumption.valueHelpDefinition: [ { entity: { name: 'ZI_VH_PLANT', element: 'Plant' } } ]
      Plant,
      @AnalyticsDetails.query.axis: #FREE
      @Consumption.valueHelpDefinition: [ { entity: { name: 'I_Product', element: 'Product' } } ]
      Material,
      @AnalyticsDetails.query.axis: #FREE
      ItemText,
      @AnalyticsDetails.query.axis: #FREE
      IsCompletelyDelivered,
      @AnalyticsDetails.query.axis: #FREE
      IsFinallyInvoiced,
      @AnalyticsDetails.query.axis: #FREE
      DeletionCode,
      @AnalyticsDetails.query.axis: #FREE
      OrderUnit,
      @AnalyticsDetails.query.axis: #FREE
      Currency,
      @AnalyticsDetails.query.axis: #FREE
      PoCreationDate,
      @AnalyticsDetails.query.axis: #COLUMNS
      OrderQuantity,
      @AnalyticsDetails.query.axis: #COLUMNS
      NetAmount,
      @AnalyticsDetails.query.axis: #COLUMNS
      RecordCount
}
