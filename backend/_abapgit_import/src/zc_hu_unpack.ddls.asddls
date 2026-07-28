@EndUserText.label: 'HU Unpack - Projection'
@AccessControl.authorizationCheck: #CHECK
@Metadata.allowExtensions: true
@Search.searchable: true
define root view entity ZC_HU_UNPACK
  provider contract transactional_query
  as projection on ZI_HU_UNPACK
{
  @Search.defaultSearchElement: true
  key HandlingUnit,
  key HandlingUnitItem,
      Material,
      Batch,
      Quantity,
      Unit
}
