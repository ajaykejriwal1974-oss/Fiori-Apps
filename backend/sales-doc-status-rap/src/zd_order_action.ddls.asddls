@EndUserText.label: 'Sales order close action - import'
define abstract entity ZD_OrderAction
{
  SalesOrder : abap.char(10);
  Reason     : abap.char(2);
}
