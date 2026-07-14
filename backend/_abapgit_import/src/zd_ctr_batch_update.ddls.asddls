@EndUserText.label: 'Update Contract Batches - action import (header)'
define abstract entity ZD_CTR_BATCH_UPDATE
{
  SalesContract : abap.char(10);
  _Item : composition [0..*] of ZD_CTR_BATCH_ITEM;
}
