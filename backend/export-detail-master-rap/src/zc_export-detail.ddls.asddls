@EndUserText.label: 'Export Details - Projection'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
@Search.searchable: true
@ObjectModel.semanticKey: ['ExportId']
define root view entity ZC_ExportDetail
  provider contract transactional_query
  as projection on ZI_ExportDetail
{
  key ExportId,
      @Search.defaultSearchElement: true
      Customer,
      Country,
      Incoterms,
      Currency,
      IsActive,
      CreatedBy,
      CreatedAt,
      LastChangedBy,
      LastChangedAt,
      LocalLastChangedAt
}
