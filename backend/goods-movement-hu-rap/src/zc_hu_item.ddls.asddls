@EndUserText.label: 'Handling Unit Items - Projection'
@AccessControl.authorizationCheck: #CHECK
@Metadata.allowExtensions: true
@Search.searchable: true
@ObjectModel.semanticKey: ['HandlingUnit', 'HandlingUnitItem']
define root view entity ZC_HU_Item
  provider contract transactional_query
  as projection on ZI_HU_Item
{
      @Search.defaultSearchElement: true
  key HandlingUnit,
  key HandlingUnitItem,
      Material,
      Batch,
      Quantity,
      Unit,
      Plant,
      StorageLocation
}
