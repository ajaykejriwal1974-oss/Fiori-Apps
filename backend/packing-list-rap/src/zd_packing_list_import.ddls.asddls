@EndUserText.label: 'Packing List action - import'
// Flat action parameter for create / change. BoxList carries the box numbers as
// 'BOX1;BOX2;BOX3' (same convention as ZD_DISPATCH_CORRECT). For deletePackingList
// only SalesOrder + PackListItem are read.
define abstract entity ZD_PACKING_LIST_IMPORT
{
  SalesOrder     : abap.char(10);
  SalesOrderItem : abap.numc(6);
  PackListItem   : abap.numc(6);
  Plant          : abap.char(4);
  Status         : abap.char(4);
  BoxList        : abap.char(1333);
}
