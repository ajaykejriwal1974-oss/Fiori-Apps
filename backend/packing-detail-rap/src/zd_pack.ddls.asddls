@EndUserText.label: 'packItems - import'
define abstract entity ZD_Pack
{
  PackagingMaterial : abap.char(18);
  Reference : abap.char(20);
  _Item : composition [0..*] of ZD_PackItem;
}
