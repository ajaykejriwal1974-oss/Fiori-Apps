@EndUserText.label: 'Packing Details - Projection'
@AccessControl.authorizationCheck: #CHECK
@Metadata.allowExtensions: true
@Search.searchable: true
define root view entity ZC_PackingItem
  provider contract transactional_query
  as projection on ZI_PackingItem
{
  key HandlingUnit,
  key HandlingUnitItem,
      Material,
      Batch,
      Quantity,
      Unit
}
