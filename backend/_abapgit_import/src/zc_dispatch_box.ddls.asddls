@EndUserText.label: 'Dispatch Boxes - Projection'
@AccessControl.authorizationCheck: #CHECK
@Metadata.allowExtensions: true
@Search.searchable: true
@ObjectModel.semanticKey: ['BoxNumber']
define root view entity ZC_DISPATCH_BOX
  provider contract transactional_query
  as projection on ZI_DISPATCH_BOX
{
      @Search.defaultSearchElement: true
      @UI: { lineItem: [ { position: 10, importance: #HIGH } ], selectionField: [ { position: 10 } ] }
  key BoxNumber,
      @Consumption.valueHelpDefinition: [ { entity: { name: 'I_SalesOrder', element: 'SalesOrder' } } ]
      @UI: { lineItem: [ { position: 20, importance: #HIGH } ], selectionField: [ { position: 20 } ] }
      SalesOrder,
      @UI: { lineItem: [ { position: 30 } ] }
      SalesOrderItem,
      @UI: { lineItem: [ { position: 40 } ] }
      PackListItem,
      @UI: { lineItem: [ { position: 50 } ], selectionField: [ { position: 40 } ] }
      Status,
      @UI: { lineItem: [ { position: 60 } ] }
      CreatedOnDate,
      CreatedAtTime,
      @Consumption.valueHelpDefinition: [ { entity: { name: 'I_Product', element: 'Product' } } ]
      @UI: { lineItem: [ { position: 70, importance: #HIGH } ], selectionField: [ { position: 30 } ] }
      Material,
      @UI: { lineItem: [ { position: 80 } ] }
      Grade,
      @UI: { lineItem: [ { position: 90, importance: #HIGH } ] }
      NetWeight
}
