@EndUserText.label: 'Job Master - Projection'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
@Search.searchable: true
@ObjectModel.semanticKey: ['JobNumber']
define root view entity ZC_Job
  provider contract transactional_query
  as projection on ZI_Job
{
  key JobNumber,
      @Search.defaultSearchElement: true
      JobName,
      JobType,
      Plant,
      WorkCenter,
      IsActive,
      CreatedBy,
      CreatedAt,
      LastChangedBy,
      LastChangedAt,
      LocalLastChangedAt
}
