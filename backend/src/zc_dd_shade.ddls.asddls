@EndUserText.label: 'Shade Master (Dope Dyeing) - Projection'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
@Search.searchable: true
@ObjectModel.semanticKey: ['ShadeCode']
define root view entity ZC_DD_Shade
  provider contract transactional_query
  as projection on ZI_DD_Shade
{
      @Search.defaultSearchElement: true
      @Search.fuzzinessThreshold: 0.8
  key ShadeCode,
      @Search.defaultSearchElement: true
      ShadeName,
      ColorFamily,
      RgbHex,
      Lustre,
      IsActive,
      CreatedBy,
      CreatedAt,
      LastChangedBy,
      LastChangedAt,
      LocalLastChangedAt
}
