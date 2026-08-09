@EndUserText.label: 'repackItems - import item'
define abstract entity ZD_RepackItem
{
  HandlingUnitItem : abap.numc(4);
  Quantity : abap.quan(13,3);
}
