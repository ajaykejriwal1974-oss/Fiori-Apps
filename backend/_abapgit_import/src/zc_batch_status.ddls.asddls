@EndUserText.label: 'Batch Status - Projection'
@AccessControl.authorizationCheck: #CHECK
@Metadata.allowExtensions: true
@Search.searchable: true
define root view entity ZC_BATCH_STATUS
  provider contract transactional_query
  as projection on ZI_BATCH_STATUS
{
      @Search.defaultSearchElement: true
      @Consumption.valueHelpDefinition: [{ entity: { name: 'I_Product', element: 'Product' } }]
      @UI: { lineItem: [ { position: 10, importance: #HIGH } ], selectionField: [ { position: 10 } ] }
  key Material,
      @Consumption.valueHelpDefinition: [{ entity: { name: 'ZI_VH_PLANT', element: 'Plant' } }]
      @UI: { lineItem: [ { position: 20, importance: #HIGH } ], selectionField: [ { position: 20 } ] }
  key Plant,
      @UI: { lineItem: [ { position: 30 } ], selectionField: [ { position: 30 } ] }
  key Batch,
      @UI: { lineItem: [ { position: 40 } ] }
      LastGoodsReceiptDate
}
