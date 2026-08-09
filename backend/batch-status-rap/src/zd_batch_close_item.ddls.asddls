@EndUserText.label: 'closeBatch - import item'
define abstract entity ZD_BatchCloseItem
{
  Material : abap.char(40);
  Plant : abap.char(4);
  Batch : abap.char(10);
}
