@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Merge Details - Interface'
@Metadata.allowExtensions: true
@ObjectModel.semanticKey: ['MergeId']
// Custom master (Route 7) - managed RAP, same pattern as ZDD_SHADE.
// VERIFY the field list against the original Z program before activating. Likely a batch/lot merge log - VERIFY the exact purpose against ZMERGE.
define root view entity ZI_Merge
  as select from zmerge
{
  key merge_id                   as MergeId,
      material                   as Material,
      source_batch               as SourceBatch,
      target_batch               as TargetBatch,
      merge_date                 as MergeDate,
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
