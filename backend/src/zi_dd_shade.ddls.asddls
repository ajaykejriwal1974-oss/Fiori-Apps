@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Shade Master (Dope Dyeing) - Interface'
@Metadata.allowExtensions: true
@ObjectModel.semanticKey: ['ShadeCode']
define root view entity ZI_DD_Shade
  as select from zdd_shade
{
  key shade_code                    as ShadeCode,
      shade_name                    as ShadeName,
      color_family                  as ColorFamily,
      rgb_hex                       as RgbHex,
      lustre                        as Lustre,
      is_active                     as IsActive,
      @Semantics.user.createdBy: true
      created_by                    as CreatedBy,
      @Semantics.systemDateTime.createdAt: true
      created_at                    as CreatedAt,
      @Semantics.user.lastChangedBy: true
      last_changed_by               as LastChangedBy,
      @Semantics.systemDateTime.lastChangedAt: true
      last_changed_at               as LastChangedAt,
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      local_last_changed_at         as LocalLastChangedAt
}
