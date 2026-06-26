@EndUserText.label: 'convertToMts - import'
define abstract entity ZD_MtoMts
{
  Material : abap.char(40);
  Plant : abap.char(4);
  SalesOrder : abap.char(10);
  SalesOrderItem : abap.numc(6);
  Quantity : abap.quan(13,3);
  BaseUnit : abap.unit(3);
}
