@EndUserText.label: 'deleteBatch - import'
define abstract entity ZD_BatchDelete
{
  Material : abap.char(40);
  Plant : abap.char(4);
  Batch : abap.char(10);
}
