@EndUserText.label: 'Sales Contracts (status actions) - Projection'
@AccessControl.authorizationCheck: #CHECK
@Metadata.allowExtensions: true
@Search.searchable: true
@ObjectModel.semanticKey: ['SalesContract']
define root view entity ZC_SalesContract
  provider contract transactional_query
  as projection on ZI_SalesContract
{
      @Search.defaultSearchElement: true
  key SalesContract,
      SalesContractType,
      SalesOrganization,
      SoldToParty,
      NetValue,
      Currency,
      OverallProcessingStatus,
      CreatedOnDate
}
