@EndUserText.label: 'Merge Details - Projection'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
@Search.searchable: true
@ObjectModel.semanticKey: ['MergeId']
define root view entity ZC_Merge
  provider contract transactional_query
  as projection on ZI_Merge
{
  key MergeId,
      @Search.defaultSearchElement: true
      Material,
      SourceBatch,
      TargetBatch,
      MergeDate,
      IsActive,
      CreatedBy,
      CreatedAt,
      LastChangedBy,
      LastChangedAt,
      LocalLastChangedAt
}
