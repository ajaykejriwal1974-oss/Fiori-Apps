@EndUserText.label: 'unpackItems - import item'
define abstract entity ZD_HuUnpackItem
{
  HandlingUnit : abap.char(20);
  Material : abap.char(40);
  Batch : abap.char(10);
  Quantity : abap.quan(13,3);
  Unit : abap.unit(3);
}
