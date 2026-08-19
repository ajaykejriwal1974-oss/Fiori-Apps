@EndUserText.label: 'packItems - import'
// Flat action parameter. ItemList carries 'MATERIAL=BATCH=QTY=UNIT;...'
// (decimal point in QTY, e.g. 'MAT1=B001=10.500=KG').
define abstract entity ZD_PACK
{
  PackagingMaterial : abap.char(18);
  Reference         : abap.char(20);
  ItemList          : abap.char(1333);
}
