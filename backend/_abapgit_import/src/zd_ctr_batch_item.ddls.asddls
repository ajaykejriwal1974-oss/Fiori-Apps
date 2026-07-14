@EndUserText.label: 'Update Contract Batches - action import (item)'
define abstract entity ZD_CTR_BATCH_ITEM
{
  ContractItem : abap.numc(6);
  NewBatch     : abap.char(10);
}
