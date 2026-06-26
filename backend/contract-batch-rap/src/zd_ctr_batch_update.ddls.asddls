@EndUserText.label: 'Update Contract Batches - action import (header)'
define abstract entity ZD_Ctr_Batch_Update
{
  SalesContract : abap.char(10);
  _Item : composition [0..*] of ZD_Ctr_Batch_Item;
}
