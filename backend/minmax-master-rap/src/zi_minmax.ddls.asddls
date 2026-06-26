@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Min-Max Levels - Interface'
@Metadata.allowExtensions: true
@ObjectModel.semanticKey: ['Material', 'Plant']
// Custom master (Route 7) - managed RAP, same pattern as ZDD_SHADE.
// VERIFY the field list against the original Z program before activating.
define root view entity ZI_MinMax
  as select from zminmax
{
  key material                   as Material,
  key plant                      as Plant,
      min_qty                    as MinimumQty,
      max_qty                    as MaximumQty,
      base_unit                  as BaseUnit,
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
