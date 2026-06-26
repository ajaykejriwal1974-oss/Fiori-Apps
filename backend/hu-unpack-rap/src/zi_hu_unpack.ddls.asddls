@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'HU Unpack - Interface'
@Metadata.allowExtensions: true
@ObjectModel.semanticKey: ['HandlingUnit', 'HandlingUnitItem']
// Item-level read via the shared HU base (audit P3). unpackItems action lives on
// the behavior (replaces ZSOL_INW_HU_UNPACK / ZHUPK).
define root view entity ZI_HuUnpackItem
  as select from ZI_HU_ItemBase
{
  key HandlingUnit,
  key HandlingUnitItem,
      Material,
      Batch,
      Quantity,
      Unit
}
