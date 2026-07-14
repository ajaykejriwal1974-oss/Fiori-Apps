@EndUserText.label: 'Correct Dispatch - import'
define abstract entity ZD_DISPATCH_CORRECT
{
  NewSalesOrder     : abap.char(10);
  NewSalesOrderItem : abap.numc(6);
  NewStatus         : abap.char(4);
  _Item : composition [0..*] of ZD_DISPATCH_CORRECT_ITEM;
}
