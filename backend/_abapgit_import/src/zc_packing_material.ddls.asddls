@EndUserText.label: 'Packing Material Master - Projection'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
@Search.searchable: true
@ObjectModel.semanticKey: ['PackingType', 'WorkCenter', 'Material']
define root view entity ZC_PACKING_MATERIAL
  provider contract transactional_query
  as projection on ZI_PACKING_MATERIAL
{
      @Search.defaultSearchElement: true
      @UI: { lineItem: [ { position: 10, importance: #HIGH } ], selectionField: [ { position: 10 } ] }
  key PackingType,
      @UI: { lineItem: [ { position: 20 } ], selectionField: [ { position: 30 } ] }
  key WorkCenter,
      @Consumption.valueHelpDefinition: [{ entity: { name: 'I_Product', element: 'Product' } }]
      @UI: { lineItem: [ { position: 30, importance: #HIGH } ], selectionField: [ { position: 20 } ] }
  key Material,
      @UI: { lineItem: [ { position: 40 } ] }
      StorageLocation,
      @UI: { lineItem: [ { position: 50 } ] }
      Batch,
      @UI: { lineItem: [ { position: 60 } ] }
      Sequence
}
