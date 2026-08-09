@EndUserText.label: 'Create Packing HUs - action import'
// Flat action parameter. UnitList carries the HU levels bottom-up as
// 'PACKMAT=QTY;PACKMAT=QTY' (e.g. cone, then carton, then pallet).
define abstract entity ZD_PACK_CREATE
{
  Reference : abap.char(20);   //  production order / delivery
  Material  : abap.char(40);
  Batch     : abap.char(10);
  Shade     : abap.char(10);
  UnitList  : abap.char(1333);
}
