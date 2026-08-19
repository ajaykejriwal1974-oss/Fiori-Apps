@EndUserText.label: 'Sales order close action - result'
define abstract entity ZD_ORDER_RESULT
{
  SalesOrder : abap.char(10);
  NewStatus  : abap.char(1);
  Message    : abap.string;
}
