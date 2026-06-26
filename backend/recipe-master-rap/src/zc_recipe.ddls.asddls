@EndUserText.label: 'Dyeing Recipe Master - Projection'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
@Search.searchable: true
@ObjectModel.semanticKey: ['RecipeCode']
define root view entity ZC_Recipe
  provider contract transactional_query
  as projection on ZI_Recipe
{
  key RecipeCode,
      @Search.defaultSearchElement: true
      RecipeName,
      ShadeCode,
      ProcessType,
      Temperature,
      DurationInMinutes,
      IsActive,
      CreatedBy,
      CreatedAt,
      LastChangedBy,
      LastChangedAt,
      LocalLastChangedAt
}
