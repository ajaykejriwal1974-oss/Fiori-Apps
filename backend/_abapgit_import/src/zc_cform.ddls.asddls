@EndUserText.label: 'C-Form Allocation Master - Projection'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
@Search.searchable: true
@ObjectModel.semanticKey: ['SalesOrganization', 'Customer', 'BillingDocument']
define root view entity ZC_Cform
  provider contract transactional_query
  as projection on ZI_Cform
{
      @Consumption.valueHelpDefinition: [{ entity: { name: 'ZI_VH_SALESORG', element: 'SalesOrganization' } }]
      @UI: { lineItem: [ { position: 10, importance: #HIGH } ], selectionField: [ { position: 10 } ] }
  key SalesOrganization,
      @Consumption.valueHelpDefinition: [{ entity: { name: 'I_Customer', element: 'Customer' } }]
      @UI: { lineItem: [ { position: 20, importance: #HIGH } ], selectionField: [ { position: 20 } ] }
  key Customer,
      @Search.defaultSearchElement: true
      @UI: { lineItem: [ { position: 30, importance: #HIGH } ], selectionField: [ { position: 30 } ] }
  key BillingDocument,
      @UI: { lineItem: [ { position: 40 } ] }
      BillingDate,
      @UI: { lineItem: [ { position: 50 } ] }
      InvoiceValue,
      @UI: { lineItem: [ { position: 60 } ], selectionField: [ { position: 40 } ] }
      FormType,
      @UI: { lineItem: [ { position: 70 } ] }
      FormNumber,
      @UI: { lineItem: [ { position: 80 } ] }
      FormDate,
      @UI: { lineItem: [ { position: 90 } ] }
      AllocatedValue,
      @UI: { lineItem: [ { position: 100 } ] }
      Quantity
}
