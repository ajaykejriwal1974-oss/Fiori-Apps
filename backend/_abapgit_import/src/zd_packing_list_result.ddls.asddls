@EndUserText.label: 'Packing List action - result'
define abstract entity ZD_PACKING_LIST_RESULT
{
  BoxesAffected : abap.int4;
  PackListItem  : abap.numc(6);
  Message       : abap.string;
}
