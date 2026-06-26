@EndUserText.label: 'Checked / Packed By - Projection'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
@Search.searchable: true
@ObjectModel.semanticKey: ['OperatorId']
define root view entity ZC_CheckedBy
  provider contract transactional_query
  as projection on ZI_CheckedBy
{
  key OperatorId,
      @Search.defaultSearchElement: true
      OperatorName,
      OperatorRole,
      Plant,
      IsActive,
      CreatedBy,
      CreatedAt,
      LastChangedBy,
      LastChangedAt,
      LocalLastChangedAt
}
