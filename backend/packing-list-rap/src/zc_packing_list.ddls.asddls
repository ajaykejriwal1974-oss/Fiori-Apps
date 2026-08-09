@EndUserText.label: 'Packing List - Projection'
@AccessControl.authorizationCheck: #CHECK
@Metadata.allowExtensions: true
@Search.searchable: true
@ObjectModel.semanticKey: ['BoxNumber']
define root view entity ZC_PACKING_LIST
  provider contract transactional_query
  as projection on ZI_PACKING_LIST
{
      @Search.defaultSearchElement: true
      @UI: { lineItem: [ { position: 10, importance: #HIGH } ], selectionField: [ { position: 10 } ] }
  key BoxNumber,
      @UI: { lineItem: [ { position: 20 } ] }
  key BoxYear,
      @Consumption.valueHelpDefinition: [{ entity: { name: 'I_SalesOrder', element: 'SalesOrder' } }]
      @UI: { lineItem: [ { position: 30, importance: #HIGH } ], selectionField: [ { position: 20 } ] }
      SalesOrder,
      @UI: { lineItem: [ { position: 40 } ] }
      SalesOrderItem,
      @UI: { lineItem: [ { position: 50 } ] }
      PackListItem,
      @Consumption.valueHelpDefinition: [{ entity: { name: 'ZI_VH_PLANT', element: 'Plant' } }]
      @UI: { lineItem: [ { position: 60 } ], selectionField: [ { position: 30 } ] }
      Plant,
      @Consumption.valueHelpDefinition: [{ entity: { name: 'I_Product', element: 'Product' } }]
      @UI: { lineItem: [ { position: 70, importance: #HIGH } ], selectionField: [ { position: 40 } ] }
      Material,
      @UI: { lineItem: [ { position: 80 } ], selectionField: [ { position: 50 } ] }
      Grade,
      @UI: { lineItem: [ { position: 90 } ] }
      NetWeight,
      @UI: { lineItem: [ { position: 100 } ] }
      PackListDate,
      @UI: { lineItem: [ { position: 110 } ] }
      Status
}
