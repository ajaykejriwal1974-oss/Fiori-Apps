@EndUserText.label: 'closeBatch - import'
define abstract entity ZD_BATCH_CLOSE
{
  Material : abap.char(40);
  Plant : abap.char(4);
  Batch : abap.char(10);
}
