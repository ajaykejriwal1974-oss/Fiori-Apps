@EndUserText.label: 'Create Packing HUs - action import (header)'
define abstract entity ZD_Pack_Create
{
  Reference : abap.char(20);   //  production order / delivery
  Material  : abap.char(40);
  Batch     : abap.char(10);
  Shade     : abap.char(10);
  _Unit : composition [0..*] of ZD_Pack_Create_Unit;
}
