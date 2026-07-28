@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Post Packing & GR - Interface'
@Metadata.allowExtensions: true
// Header-level read via the shared HU base (audit P3). postPackingAndGr action on
// the behavior (replaces ZPP_PACK_POST / ZPOST01).
define root view entity ZI_POST_PACKING_GR
  as select from ZI_HU_HEADER_BASE
{
  key HandlingUnit,
      PackagingMaterial,
      Reference
}
