@EndUserText.label: 'Handling Unit Items - Projection'
@AccessControl.authorizationCheck: #CHECK
@Metadata.allowExtensions: true
@Search.searchable: true
@ObjectModel.semanticKey: ['HandlingUnit', 'HandlingUnitItem']
define root view entity ZC_HU_ITEM
  provider contract transactional_query
  as projection on ZI_HU_ITEM
{
      @Search.defaultSearchElement: true
      @UI: { lineItem: [ { position: 10, importance: #HIGH } ], selectionField: [ { position: 10 } ] }
  key HandlingUnit,
      @UI: { lineItem: [ { position: 20 } ] }
  key HandlingUnitItem,
      @Consumption.valueHelpDefinition: [{ entity: { name: 'I_Product', element: 'Product' } }]
      @UI: { lineItem: [ { position: 30, importance: #HIGH } ], selectionField: [ { position: 20 } ] }
      Material,
      @UI: { lineItem: [ { position: 40 } ], selectionField: [ { position: 40 } ] }
      Batch,
      @UI: { lineItem: [ { position: 50 } ] }
      Quantity,
      @UI: { lineItem: [ { position: 60 } ] }
      Unit,
      @Consumption.valueHelpDefinition: [{ entity: { name: 'ZI_VH_PLANT', element: 'Plant' } }]
      @UI: { lineItem: [ { position: 70 } ], selectionField: [ { position: 30 } ] }
      Plant,
      @UI: { lineItem: [ { position: 80 } ] }
      StorageLocation
}
