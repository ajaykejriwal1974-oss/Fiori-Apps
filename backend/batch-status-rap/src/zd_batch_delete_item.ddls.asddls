@EndUserText.label: 'deleteBatch - import item'
define abstract entity ZD_BatchDeleteItem
{
  Material : abap.char(40);
  Plant : abap.char(4);
  Batch : abap.char(10);
}
