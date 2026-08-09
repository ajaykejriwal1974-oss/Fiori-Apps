@EndUserText.label: 'Sales Contract Items - Projection'
@AccessControl.authorizationCheck: #CHECK
@Metadata.allowExtensions: true
@Search.searchable: true
@ObjectModel.semanticKey: ['SalesContract', 'ContractItem']
define root view entity ZC_CONTRACT_ITEM
  provider contract transactional_query
  as projection on ZI_CONTRACT_ITEM
{
      @Search.defaultSearchElement: true
      @UI: { lineItem: [ { position: 10, importance: #HIGH } ], selectionField: [ { position: 10 } ] }
  key SalesContract,
      @UI: { lineItem: [ { position: 20 } ] }
  key ContractItem,
      @Consumption.valueHelpDefinition: [{ entity: { name: 'I_Product', element: 'Product' } }]
      @UI: { lineItem: [ { position: 30, importance: #HIGH } ], selectionField: [ { position: 20 } ] }
      Material,
      @UI: { lineItem: [ { position: 40 } ] }
      MaterialDescription,
      @UI: { lineItem: [ { position: 50 } ] }
      CurrentBatch,
      @Consumption.valueHelpDefinition: [{ entity: { name: 'ZI_VH_PLANT', element: 'Plant' } }]
      @UI: { lineItem: [ { position: 60 } ], selectionField: [ { position: 30 } ] }
      Plant
}
