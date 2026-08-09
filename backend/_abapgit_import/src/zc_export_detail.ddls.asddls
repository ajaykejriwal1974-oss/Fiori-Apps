@EndUserText.label: 'Export Details Master - Projection'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
@Search.searchable: true
@ObjectModel.semanticKey: ['BillingDocument', 'ConditionType']
define root view entity ZC_EXPORT_DETAIL
  provider contract transactional_query
  as projection on ZI_EXPORT_DETAIL
{
      @Search.defaultSearchElement: true
      @UI: { lineItem: [ { position: 10, importance: #HIGH } ], selectionField: [ { position: 10 } ] }
  key BillingDocument,
      @UI: { lineItem: [ { position: 20 } ], selectionField: [ { position: 20 } ] }
  key ConditionType,
      @UI: { lineItem: [ { position: 30 } ] }
      NetValue,
      @Consumption.valueHelpDefinition: [{ entity: { name: 'I_Currency', element: 'Currency' } }]
      @UI: { lineItem: [ { position: 40 } ], selectionField: [ { position: 30 } ] }
      Currency,
      @UI: { lineItem: [ { position: 50 } ] }
      ExchangeRate,
      @UI: { lineItem: [ { position: 60 } ] }
      BillingDate
}
