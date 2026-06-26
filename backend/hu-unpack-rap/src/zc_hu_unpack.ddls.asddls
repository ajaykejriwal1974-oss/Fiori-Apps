@EndUserText.label: 'HU Unpack - Projection'
@AccessControl.authorizationCheck: #CHECK
@Metadata.allowExtensions: true
@Search.searchable: true
define root view entity ZC_HuUnpackItem
  provider contract transactional_query
  as projection on ZI_HuUnpackItem
{
  key HandlingUnit,
  key HandlingUnitItem,
      Material,
      Batch,
      Quantity,
      Unit
}
