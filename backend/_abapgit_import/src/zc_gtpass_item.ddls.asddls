@EndUserText.label: 'Gate Pass Item - Projection'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
@Search.searchable: true
@ObjectModel.semanticKey: ['GpNumber', 'ItemNumber', 'FiscalYear']
define root view entity ZC_GTPASS_ITEM
  provider contract transactional_query
  as projection on ZI_GTPASS_ITEM
{
      @Search.defaultSearchElement: true
      @UI: { lineItem: [ { position: 10, importance: #HIGH } ], selectionField: [ { position: 10 } ] }
  key GpNumber,
      @UI: { lineItem: [ { position: 20 } ] }
  key ItemNumber,
      @UI: { lineItem: [ { position: 30 } ] }
  key FiscalYear,
      @Consumption.valueHelpDefinition: [{ entity: { name: 'I_Product', element: 'Product' } }]
      @UI: { lineItem: [ { position: 40, importance: #HIGH } ], selectionField: [ { position: 20 } ] }
      Material,
      @UI: { lineItem: [ { position: 50 } ] }
      MaterialDescription,
      @Consumption.valueHelpDefinition: [{ entity: { name: 'I_Supplier', element: 'Supplier' } }]
      @UI: { lineItem: [ { position: 60 } ], selectionField: [ { position: 30 } ] }
      Supplier,
      @UI: { lineItem: [ { position: 70 } ] }
      SupplierName,
      @UI: { lineItem: [ { position: 80 } ] }
      Quantity,
      @UI: { lineItem: [ { position: 90 } ] }
      Unit
}
