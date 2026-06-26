@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Digital Signature - Interface'
@Metadata.allowExtensions: true
@ObjectModel.semanticKey: ['SignatoryId']
// Custom master (Route 7) - managed RAP, same pattern as ZDD_SHADE.
// VERIFY the field list against the original Z program before activating. Confirm this is a business signatory master, NOT a Basis/security digital-signature setting.
define root view entity ZI_DigSign
  as select from zdigsign
{
  key signatory_id               as SignatoryId,
      signatory_name             as SignatoryName,
      designation                as Designation,
      valid_from                 as ValidFrom,
      valid_to                   as ValidTo,
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
