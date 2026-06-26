@EndUserText.label: 'Min-Max Levels - Projection'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
@Search.searchable: true
@ObjectModel.semanticKey: ['Material', 'Plant']
define root view entity ZC_MinMax
  provider contract transactional_query
  as projection on ZI_MinMax
{
  key Material,
  key Plant,
      @Search.defaultSearchElement: true
      MinimumQty,
      MaximumQty,
      BaseUnit,
      IsActive,
      CreatedBy,
      CreatedAt,
      LastChangedBy,
      LastChangedAt,
      LocalLastChangedAt
}
