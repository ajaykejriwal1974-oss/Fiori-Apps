@EndUserText.label: 'Correct Dispatch - import'
// Flat action parameter. BoxList carries the box numbers as 'BOX1;BOX2;BOX3'.
define abstract entity ZD_DISPATCH_CORRECT
{
  NewSalesOrder     : abap.char(10);
  NewSalesOrderItem : abap.numc(6);
  NewStatus         : abap.char(4);
  BoxList           : abap.char(1333);
}
