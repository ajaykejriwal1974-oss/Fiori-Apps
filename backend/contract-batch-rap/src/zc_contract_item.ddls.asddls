@EndUserText.label: 'Sales Contract Items - Projection'
@AccessControl.authorizationCheck: #CHECK
@Metadata.allowExtensions: true
@Search.searchable: true
@ObjectModel.semanticKey: ['SalesContract', 'ContractItem']
define root view entity ZC_CONTRACT_ITEM
  provider contract transactional_query
  as projection on ZI_CONTRACT_ITEM
{
  key SalesContract,
  key ContractItem,
      Material,
      MaterialDescription,
      CurrentBatch,
      Plant
}
