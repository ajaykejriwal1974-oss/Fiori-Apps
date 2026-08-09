@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Packing Details - Interface'
@Metadata.allowExtensions: true
@ObjectModel.semanticKey: ['HandlingUnit', 'HandlingUnitItem']
// Item-level read via the shared HU base (audit P3); packItems/repackItems
// actions live on the behavior. Replaces ZPP_PACK_MODULE_NEW (ZPACK01/02/03N, ZREPACK).
define root view entity ZI_PACKING_DETAIL
  as select from ZI_HU_ITEM_BASE
{
  key HandlingUnit,
  key HandlingUnitItem,
      Material,
      Batch,
      Quantity,
      Unit
}
