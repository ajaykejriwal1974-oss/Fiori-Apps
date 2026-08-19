@EndUserText.label: 'Vendor Invoice Allocation - Projection'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
@Search.searchable: true
@ObjectModel.semanticKey: ['InvoiceNumber']
define root view entity ZC_VFORM
  provider contract transactional_query
  as projection on ZI_VFORM
{
      @Search.defaultSearchElement: true
      @Search.fuzzinessThreshold: 0.8
      @UI: { lineItem: [ { position: 10, importance: #HIGH } ], selectionField: [ { position: 10 } ] }
  key InvoiceNumber,
      @UI: { lineItem: [ { position: 20 } ], selectionField: [ { position: 30 } ] }
      PurchasingDocument,
      @UI: { lineItem: [ { position: 30 } ] }
      ReferenceNumber,
      @Search.defaultSearchElement: true
      @Consumption.valueHelpDefinition: [{ entity: { name: 'I_Supplier', element: 'Supplier' } }]
      @UI: { lineItem: [ { position: 40, importance: #HIGH } ], selectionField: [ { position: 20 } ] }
      Supplier,
      @Search.defaultSearchElement: true
      @UI: { lineItem: [ { position: 50, importance: #HIGH } ] }
      SupplierName,
      @UI: { lineItem: [ { position: 60 } ] }
      InvoiceDate,
      @UI: { lineItem: [ { position: 70 } ] }
      InvoiceValue,
      @UI: { lineItem: [ { position: 80 } ] }
      AllocatedValue,
      @UI: { lineItem: [ { position: 90 } ] }
      UnallocatedValue,
      @UI: { lineItem: [ { position: 100 } ], selectionField: [ { position: 40 } ] }
      AllocatedFlag,
      @UI: { lineItem: [ { position: 110 } ] }
      FormType,
      @UI: { lineItem: [ { position: 120 } ] }
      FormNumber,
      @UI: { lineItem: [ { position: 130 } ] }
      FormDate,
      @UI: { lineItem: [ { position: 140 } ] }
      FormValue,
      @UI: { lineItem: [ { position: 150 } ] }
      Quantity,
      @UI: { lineItem: [ { position: 160 } ] }
      CourierName,
      @UI: { lineItem: [ { position: 170 } ] }
      CourierDetail,
      @Consumption.valueHelpDefinition: [{ entity: { name: 'I_Currency', element: 'Currency' } }]
      @UI: { lineItem: [ { position: 180 } ] }
      Currency
}
