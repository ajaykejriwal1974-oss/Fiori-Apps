@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Checked / Packed By - Interface'
@Metadata.allowExtensions: true
@ObjectModel.semanticKey: ['OperatorId']
// Custom master (Route 7) - managed RAP, same pattern as ZDD_SHADE.
// VERIFY the field list against the original Z program before activating.
define root view entity ZI_CheckedBy
  as select from zcheckedby
{
  key operator_id                as OperatorId,
      operator_name              as OperatorName,
      operator_role              as OperatorRole,
      plant                      as Plant,
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
