@EndUserText.label: 'repackItems - import item'
define abstract entity ZD_REPACK_ITEM
{
  HandlingUnitItem : abap.numc(4);
  Quantity : abap.dec(13,3);
  _Parent : association to parent ZD_REPACK;
}
