@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Palletization - Interface'
@Metadata.allowExtensions: true
// Header-level read via the shared HU base (audit P3). packPallet action on the
// behavior (replaces ZPP_HU_CREATE / ZSOL_PALLETIZATION).
define root view entity ZI_PALLETIZATION
  as select from ZI_HU_HEADER_BASE
{
  key HandlingUnit as Pallet,
      PackagingMaterial,
      Reference,
      NetWeight,
      WeightUnit
}
