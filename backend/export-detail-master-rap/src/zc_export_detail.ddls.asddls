@EndUserText.label: 'Export Details Master - Projection'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
@Search.searchable: true
@ObjectModel.semanticKey: ['BillingDocument', 'ConditionType']
define root view entity ZC_ExportDetail
  provider contract transactional_query
  as projection on ZI_ExportDetail
{
  key BillingDocument,
  key ConditionType,
      NetValue,
      Currency,
      @Search.defaultSearchElement: true
      ExchangeRate,
      BillingDate
}
