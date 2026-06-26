@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Packing Material Master - Interface'
@Metadata.allowExtensions: true
@ObjectModel.semanticKey: ['PackingMaterial']
// Custom master (Route 7) - managed RAP, same pattern as ZDD_SHADE.
// VERIFY the field list against the original Z program before activating.
define root view entity ZI_PackMaterial
  as select from zpackmat
{
  key packing_material           as PackingMaterial,
      description                as Description,
      pack_type                  as PackType,
      tare_weight                as TareWeight,
      weight_unit                as WeightUnit,
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
