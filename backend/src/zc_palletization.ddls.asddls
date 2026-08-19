@EndUserText.label: 'Palletization - Projection'
@AccessControl.authorizationCheck: #CHECK
@Metadata.allowExtensions: true
@Search.searchable: true
define root view entity ZC_PALLETIZATION
  provider contract transactional_query
  as projection on ZI_PALLETIZATION
{
      @Search.defaultSearchElement: true
      @UI: { lineItem: [ { position: 10, importance: #HIGH } ], selectionField: [ { position: 10 } ] }
  key Pallet,
      @Consumption.valueHelpDefinition: [{ entity: { name: 'I_Product', element: 'Product' } }]
      @UI: { lineItem: [ { position: 20, importance: #HIGH } ], selectionField: [ { position: 20 } ] }
      PackagingMaterial,
      @UI: { lineItem: [ { position: 30 } ], selectionField: [ { position: 30 } ] }
      Reference,
      @UI: { lineItem: [ { position: 40 } ] }
      NetWeight,
      @UI: { lineItem: [ { position: 50 } ] }
      WeightUnit
}
