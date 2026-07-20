@EndUserText.label: 'createPhysInvDoc - import'
// Flat action parameter. ItemList carries 'MATERIAL=BATCH;MATERIAL=BATCH'.
define abstract entity ZD_PHYS_INV
{
  Plant           : abap.char(4);
  StorageLocation : abap.char(4);
  FiscalYear      : abap.numc(4);
  ItemList        : abap.char(1333);
}
