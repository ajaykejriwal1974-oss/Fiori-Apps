@EndUserText.label: 'Create Packing HUs - action import (header)'
define abstract entity ZD_PACK_CREATE
{
  Reference : abap.char(20);   //  production order / delivery
  Material  : abap.char(40);
  Batch     : abap.char(10);
  Shade     : abap.char(10);
  _Unit : composition [0..*] of ZD_PACK_CREATE_UNIT;
}
