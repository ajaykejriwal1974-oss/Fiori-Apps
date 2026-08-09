@EndUserText.label: 'Sales Contract Items - Projection'
@AccessControl.authorizationCheck: #CHECK
@Metadata.allowExtensions: true
@Search.searchable: true
@ObjectModel.semanticKey: ['SalesContract', 'ContractItem']
define root view entity ZC_Contract_Item
  provider contract transactional_query
  as projection on ZI_Contract_Item
{
  key SalesContract,
  key ContractItem,
      Material,
      MaterialDescription,
      CurrentBatch,
      Plant
}
