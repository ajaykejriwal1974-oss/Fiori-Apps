@EndUserText.label: 'Create Packing HUs - action result'
define abstract entity ZD_Pack_Result
{
  HandlingUnitsCreated : abap.int4;
  TopHandlingUnit      : abap.char(20);
  Message              : abap.string;
}
