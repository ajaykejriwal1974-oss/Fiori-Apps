@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Dyeing Packing (HU) - Interface'
@Metadata.allowExtensions: true
// Header-level read via the shared HU base (audit P3). Replaces ZPP_PACK_MODULE_DYING.
define root view entity ZI_PACKING_UNIT
  as select from ZI_HU_HEADER_BASE
{
  key HandlingUnit,
      Reference,
      PackagingMaterial,
      NetWeight,
      GrossWeight,
      WeightUnit,
      PackingGroup
}
where ReferenceObject = '01'   //  '01' = outbound delivery reference - VERIFY per scenario
