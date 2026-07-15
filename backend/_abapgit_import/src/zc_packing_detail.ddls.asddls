@EndUserText.label: 'Packing Details - Projection'
@AccessControl.authorizationCheck: #CHECK
@Metadata.allowExtensions: true
@Search.searchable: true
define root view entity ZC_PACKING_DETAIL
  provider contract transactional_query
  as projection on ZI_PACKING_DETAIL
{
  @Search.defaultSearchElement: true
  key HandlingUnit,
  key HandlingUnitItem,
      Material,
      Batch,
      Quantity,
      Unit
}
