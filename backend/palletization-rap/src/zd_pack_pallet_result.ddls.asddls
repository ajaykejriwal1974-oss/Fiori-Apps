@EndUserText.label: 'packPallet - result'
define abstract entity ZD_PackPalletResult
{
  Pallet : abap.char(20);
  BoxesPacked : abap.int4;
  Message : abap.string;
}
