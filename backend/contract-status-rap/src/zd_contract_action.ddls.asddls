@EndUserText.label: 'Contract status action - import'
define abstract entity ZD_ContractAction
{
  SalesContract : abap.char(10);
  Reason        : abap.char(2);   // optional reason for rejection / status reason
}
