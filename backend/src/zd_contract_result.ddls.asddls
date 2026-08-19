@EndUserText.label: 'Contract status action - result'
define abstract entity ZD_CONTRACT_RESULT
{
  SalesContract : abap.char(10);
  NewStatus     : abap.char(1);
  Message       : abap.string;
}
