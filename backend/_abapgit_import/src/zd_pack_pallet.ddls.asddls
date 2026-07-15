@EndUserText.label: 'packPallet - import'
// Flat action parameter. BoxHuList carries the box HU numbers as 'HU1;HU2'.
define abstract entity ZD_PACK_PALLET
{
  PalletPackagingMaterial : abap.char(18);
  Reference               : abap.char(20);
  BoxHuList               : abap.char(1333);
}
