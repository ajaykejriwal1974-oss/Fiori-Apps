@EndUserText.label: 'Update Contract Batches - action import (item)'
define abstract entity ZD_Ctr_Batch_Item
{
  ContractItem : abap.numc(6);
  NewBatch     : abap.char(10);
}
