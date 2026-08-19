@EndUserText.label: 'Contract status action - import'
define abstract entity ZD_CONTRACT_ACTION
{
  SalesContract : abap.char(10);
  Reason        : abap.char(2);
}
