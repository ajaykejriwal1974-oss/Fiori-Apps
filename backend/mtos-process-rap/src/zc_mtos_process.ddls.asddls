@EndUserText.label: 'MTOS Process - Projection'
@AccessControl.authorizationCheck: #CHECK
@Metadata.allowExtensions: true
@Search.searchable: true
@ObjectModel.semanticKey: ['Material', 'Plant', 'SalesOrder', 'SalesOrderItem']
define root view entity ZC_MTOS_PROCESS
  provider contract transactional_query
  as projection on ZI_MTOS_PROCESS
{
      @Search.defaultSearchElement: true
      @Consumption.valueHelpDefinition: [{ entity: { name: 'I_Product', element: 'Product' } }]
      @UI: { lineItem: [ { position: 10, importance: #HIGH } ], selectionField: [ { position: 10 } ] }
  key Material,
      @Consumption.valueHelpDefinition: [{ entity: { name: 'ZI_VH_PLANT', element: 'Plant' } }]
      @UI: { lineItem: [ { position: 20, importance: #HIGH } ], selectionField: [ { position: 20 } ] }
  key Plant,
      @Consumption.valueHelpDefinition: [{ entity: { name: 'I_SalesOrder', element: 'SalesOrder' } }]
      @UI: { lineItem: [ { position: 30, importance: #HIGH } ], selectionField: [ { position: 30 } ] }
  key SalesOrder,
      @UI: { lineItem: [ { position: 40 } ] }
  key SalesOrderItem,
      @UI: { lineItem: [ { position: 50 } ] }
      Quantity,
      @UI: { lineItem: [ { position: 60 } ] }
      BaseUnit
}
