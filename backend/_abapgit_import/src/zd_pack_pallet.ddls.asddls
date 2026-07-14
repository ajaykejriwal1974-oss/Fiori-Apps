@EndUserText.label: 'packPallet - import'
define abstract entity ZD_PACK_PALLET
{
  PalletPackagingMaterial : abap.char(18);
  Reference : abap.char(20);
  _Item : composition [0..*] of ZD_PACK_PALLET_BOX;
}
