@EndUserText.label: 'closeBatch - import'
define abstract entity ZD_BatchClose
{
  Material : abap.char(40);
  Plant : abap.char(4);
  Batch : abap.char(10);
}
