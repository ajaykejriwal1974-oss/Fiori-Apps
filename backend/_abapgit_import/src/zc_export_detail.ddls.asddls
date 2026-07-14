@EndUserText.label: 'Export Details Master - Projection'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
@Search.searchable: true
@ObjectModel.semanticKey: ['BillingDocument', 'ConditionType']
// Value helps reference standard released VH CDS (VERIFY the exact name per
// release); shade fields use the Shade master ZC_DD_Shade.
define root view entity ZC_ExportDetail
  provider contract transactional_query
  as projection on ZI_ExportDetail
{
  key BillingDocument,
  key ConditionType,
      NetValue,
      @Consumption.valueHelpDefinition: [{ entity: { name: 'I_CurrencyStdVH', element: 'Currency' } }]
      Currency,
      @Search.defaultSearchElement: true
      ExchangeRate,
      BillingDate
}
