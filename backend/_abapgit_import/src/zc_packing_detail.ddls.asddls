@EndUserText.label: 'Packing Details - Projection'
@AccessControl.authorizationCheck: #CHECK
@Metadata.allowExtensions: true
@Search.searchable: true
define root view entity ZC_PACKING_DETAIL
  provider contract transactional_query
  as projection on ZI_PACKING_DETAIL
{
      @Search.defaultSearchElement: true
      @UI: { lineItem: [ { position: 10, importance: #HIGH } ], selectionField: [ { position: 10 } ] }
  key HandlingUnit,
      @UI: { lineItem: [ { position: 20 } ] }
  key HandlingUnitItem,
      @Consumption.valueHelpDefinition: [{ entity: { name: 'I_Product', element: 'Product' } }]
      @UI: { lineItem: [ { position: 30, importance: #HIGH } ], selectionField: [ { position: 20 } ] }
      Material,
      @Consumption.valueHelpDefinition: [{ entity: { name: 'I_BatchStdVH', element: 'Batch' } }]
      @UI: { lineItem: [ { position: 40 } ], selectionField: [ { position: 30 } ] }
      Batch,
      @Consumption.valueHelpDefinition: [{ entity: { name: 'ZI_VH_PLANT', element: 'Plant' } }]
      @UI: { lineItem: [ { position: 45 } ], selectionField: [ { position: 15 } ] }
      Plant,
      @Consumption.valueHelpDefinition: [{ entity: { name: 'ZI_VH_COMPANYCODE', element: 'CompanyCode' } }]
      @UI: { lineItem: [ { position: 5 } ], selectionField: [ { position: 5 } ] }
      CompanyCode,
      @UI: { lineItem: [ { position: 50 } ] }
      Quantity,
      @UI: { lineItem: [ { position: 60 } ] }
      Unit
}
