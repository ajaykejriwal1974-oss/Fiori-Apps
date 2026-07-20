@EndUserText.label: 'packPallet - result'
define abstract entity ZD_PACK_PALLET_RESULT
{
  Pallet : abap.char(20);
  BoxesPacked : abap.int4;
  Message : abap.string;
}
