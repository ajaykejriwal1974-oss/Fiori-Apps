@EndUserText.label: 'Sales Document Status - Projection'
@AccessControl.authorizationCheck: #CHECK
@Metadata.allowExtensions: true
@Search.searchable: true
@ObjectModel.semanticKey: ['SalesDocument']
define root view entity ZC_SalesDocStatus
  provider contract transactional_query
  as projection on ZI_SalesDocStatus
{
      @Search.defaultSearchElement: true
  key SalesDocument,
      DocumentCategory,
      SalesDocumentType,
      SalesOrganization,
      SoldToParty,
      NetValue,
      Currency,
      OverallProcessingStatus,
      CreatedOnDate
}
