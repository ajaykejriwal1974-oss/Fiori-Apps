@EndUserText.label: 'packPallet - import'
define abstract entity ZD_PackPallet
{
  PalletPackagingMaterial : abap.char(18);
  Reference : abap.char(20);
  _Item : composition [0..*] of ZD_PackPalletBox;
}
