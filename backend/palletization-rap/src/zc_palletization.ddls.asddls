@EndUserText.label: 'Palletization - Projection'
@AccessControl.authorizationCheck: #CHECK
@Metadata.allowExtensions: true
@Search.searchable: true
define root view entity ZC_Pallet
  provider contract transactional_query
  as projection on ZI_Pallet
{
  key Pallet,
      PackagingMaterial,
      Reference,
      NetWeight,
      WeightUnit
}
