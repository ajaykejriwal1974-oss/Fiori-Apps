@EndUserText.label: 'Update pending contract rate - import'
define abstract entity ZD_PendingRate
{
  SalesContract     : abap.char(10);
  SalesContractItem : abap.numc(6);   // initial = all open items
  NewRate           : abap.curr(11,2);
  Currency          : abap.cuky;
}
