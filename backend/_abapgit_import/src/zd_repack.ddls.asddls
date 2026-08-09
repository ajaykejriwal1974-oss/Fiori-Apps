@EndUserText.label: 'repackItems - import'
// Flat action parameter. ItemList carries 'HUITEM=QTY;HUITEM=QTY'
// (decimal point in QTY).
define abstract entity ZD_REPACK
{
  SourceHandlingUnit : abap.char(20);
  TargetHandlingUnit : abap.char(20);
  ItemList           : abap.char(1333);
}
