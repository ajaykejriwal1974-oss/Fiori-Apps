@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Packing Units (existing HUs) - Interface'
@Metadata.allowExtensions: true
@ObjectModel.semanticKey: ['HandlingUnit']
//
//  Read model of the existing handling units for a reference (order/delivery),
//  used by the "Repack" flow in the dyeing-packing app (replaces ZPACK/ZREPACKD).
//  The packing CREATE is the static action createHandlingUnits (see behavior)
//  via the standard HU API (BAPI_HU_CREATE / BAPI_HU_PACK).
//
//  VERIFY vekp fields + the reference link (vpobj/vpobjkey) for your release.
//
define root view entity ZI_Packing_Unit
  as select from vekp as hu
{
  key hu.exidv                                 as HandlingUnit,
      hu.vpobjkey                              as Reference,
      hu.vhilm                                 as PackagingMaterial,
      cast( hu.ntgew as abap.quan( 15, 3 ) )   as NetWeight,
      cast( hu.brgew as abap.quan( 15, 3 ) )   as GrossWeight,
      hu.gewei                                 as WeightUnit,
      hu.vegr1                                 as PackingGroup
}
where hu.vpobj = '01'   //  '01' = outbound delivery reference - VERIFY per scenario
