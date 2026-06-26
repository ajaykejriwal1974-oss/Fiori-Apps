@EndUserText.label: 'HU Physical Inventory - Projection'
@AccessControl.authorizationCheck: #CHECK
@Metadata.allowExtensions: true
@Search.searchable: true
define root view entity ZC_HuPhysInv
  provider contract transactional_query
  as projection on ZI_HuPhysInv
{
  key HandlingUnit,
      Reference,
      PackagingMaterial
}
