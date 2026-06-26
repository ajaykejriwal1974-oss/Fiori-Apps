@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Export Details - Interface'
@Metadata.allowExtensions: true
@ObjectModel.semanticKey: ['ExportId']
// Custom master (Route 7) - managed RAP, same pattern as ZDD_SHADE.
// VERIFY the field list against the original Z program before activating. Assess against standard Foreign Trade / SD export first; build only if no standard fit.
define root view entity ZI_ExportDetail
  as select from zexportdtl
{
  key export_id                  as ExportId,
      customer                   as Customer,
      country                    as Country,
      incoterms                  as Incoterms,
      currency                   as Currency,
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
