@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Dyeing Recipe Master - Interface'
@Metadata.allowExtensions: true
@ObjectModel.semanticKey: ['RecipeCode']
// Custom master (Route 7) - managed RAP, same pattern as ZDD_SHADE.
// VERIFY the field list against the original Z program before activating.
define root view entity ZI_Recipe
  as select from zrecipe
{
  key recipe_code                as RecipeCode,
      recipe_name                as RecipeName,
      shade_code                 as ShadeCode,
      process_type               as ProcessType,
      temperature                as Temperature,
      duration_min               as DurationInMinutes,
      is_active                  as IsActive,
      @Semantics.user.createdBy: true
      created_by                 as CreatedBy,
      @Semantics.systemDateTime.createdAt: true
      created_at                 as CreatedAt,
      @Semantics.user.lastChangedBy: true
      last_changed_by            as LastChangedBy,
      @Semantics.systemDateTime.lastChangedAt: true
      last_changed_at            as LastChangedAt,
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      local_last_changed_at      as LocalLastChangedAt
}
