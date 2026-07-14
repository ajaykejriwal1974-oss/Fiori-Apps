@EndUserText.label: 'unpackItems - import item'
define abstract entity ZD_HU_UNPACK_ITEM
{
  HandlingUnit : abap.char(20);
  Material : abap.char(40);
  Batch : abap.char(10);
  Quantity : abap.dec(13,3);
  Unit : abap.unit(3);
}
