@EndUserText.label: 'Update Contract Batches - action import'
// Flat action parameter (no composition - parent/child abstract entities do
// not activate reliably on this system). ItemBatchList carries the item=batch
// pairs as 'ITEM=BATCH;ITEM=BATCH', e.g. '000010=B123;000020=B456'.
define abstract entity ZD_CTR_BATCH_UPDATE
{
  SalesContract : abap.char(10);
  ItemBatchList : abap.char(1333);
}
