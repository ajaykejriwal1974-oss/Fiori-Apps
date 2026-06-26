@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'HU Header (shared read) - Interface'
@Metadata.allowExtensions: true
// Shared header-level Handling Unit read over VEKP. Reused by the header-level
// HU services (packing-hu, hu-inbound, palletization, post-packing-gr) so the
// VEKP read + weight casts are defined ONCE - custom-app audit P3. Read-only.
// ReferenceObject (vpobj) is exposed so consumers can filter by reference type
// (e.g. '01' = outbound delivery).
define view entity ZI_HU_HeaderBase
  as select from vekp
{
  key exidv                                as HandlingUnit,
      vpobj                                as ReferenceObject,
      vpobjkey                             as Reference,
      vhilm                                as PackagingMaterial,
      cast( ntgew as abap.quan( 15, 3 ) )  as NetWeight,
      cast( brgew as abap.quan( 15, 3 ) )  as GrossWeight,
      gewei                                as WeightUnit,
      vegr1                                as PackingGroup
}
