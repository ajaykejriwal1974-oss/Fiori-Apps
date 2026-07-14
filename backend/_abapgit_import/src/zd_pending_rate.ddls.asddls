@EndUserText.label: 'Update pending contract rate - import'
define abstract entity ZD_PENDING_RATE
{
  SalesContract     : abap.char(10);
  SalesContractItem : abap.numc(6);
  NewRate           : abap.curr(11,2);
  Currency          : abap.cuky;
}
