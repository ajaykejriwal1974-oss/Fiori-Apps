@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Handling Unit Items - Interface'
@Metadata.allowExtensions: true
@ObjectModel.semanticKey: ['HandlingUnit', 'HandlingUnitItem']
// Item-level read via the shared HU base (audit P3). postGoodsMovement action
// lives on the behavior (replaces ZBOX_MOVE).
define root view entity ZI_HU_Item
  as select from ZI_HU_ItemBase
{
  key HandlingUnit,
  key HandlingUnitItem,
      Material,
      Batch,
      Quantity,
      Unit,
      Plant,
      StorageLocation
}
