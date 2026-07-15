@EndUserText.label: 'Palletization - Projection'
@AccessControl.authorizationCheck: #CHECK
@Metadata.allowExtensions: true
@Search.searchable: true
define root view entity ZC_PALLETIZATION
  provider contract transactional_query
  as projection on ZI_PALLETIZATION
{
  @Search.defaultSearchElement: true
  key Pallet,
      PackagingMaterial,
      Reference,
      NetWeight,
      WeightUnit
}
