@EndUserText.label: 'packItems - import item'
define abstract entity ZD_PACK_ITEM
{
  Material : abap.char(40);
  Batch : abap.char(10);
  Quantity : abap.dec(13,3);
  Unit : abap.unit(3);
  _Parent : association to parent ZD_PACK;
}
