@EndUserText.label: 'Contract status action - result'
define abstract entity ZD_ContractResult
{
  SalesContract : abap.char(10);
  NewStatus     : abap.char(1);
  Message       : abap.string;
}
