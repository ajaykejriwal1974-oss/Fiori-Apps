@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Dyeing Packing (HU) - Interface'
@Metadata.allowExtensions: true
// Header-level read via the shared HU base (audit P3). Replaces ZPP_PACK_MODULE_DYING.
// CompanyCode is derived via the valuation area (T001K.BWKEY = plant), the same
// pattern as ZI_HU_UNPACK / ZI_PROD_CONFIRMATION / ZI_WIP_BATCH_MGMT.
define root view entity ZI_PACKING_UNIT
  as select from ZI_HU_HEADER_BASE as hu
    left outer join t001k as vcc on vcc.bwkey = hu.Plant
{
  key hu.HandlingUnit      as HandlingUnit,
      hu.Plant             as Plant,
      vcc.bukrs            as CompanyCode,
      hu.Reference         as Reference,
      hu.PackagingMaterial as PackagingMaterial,
      hu.NetWeight         as NetWeight,
      hu.GrossWeight       as GrossWeight,
      hu.WeightUnit        as WeightUnit,
      hu.PackingGroup      as PackingGroup
}
where hu.ReferenceObject = '01'   //  '01' = outbound delivery reference - VERIFY per scenario
