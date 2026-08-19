@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Packing Details - Interface'
@Metadata.allowExtensions: true
@ObjectModel.semanticKey: ['HandlingUnit', 'HandlingUnitItem']
// Plant from HU base; CompanyCode derived via valuation area (T001K.BWKEY=plant).
define root view entity ZI_PACKING_DETAIL
  as select from ZI_HU_ITEM_BASE as base
    left outer join t001k as vcc on vcc.bwkey = base.Plant
{
  key base.HandlingUnit     as HandlingUnit,
  key base.HandlingUnitItem as HandlingUnitItem,
      base.Material         as Material,
      base.Batch            as Batch,
      base.Plant            as Plant,
      vcc.bukrs             as CompanyCode,
      base.Quantity         as Quantity,
      base.Unit             as Unit
}
