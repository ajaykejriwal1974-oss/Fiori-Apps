@EndUserText.label: 'convertToMts - import item'
define abstract entity ZD_MtoMtsItem
{
  Material : abap.char(40);
  Plant : abap.char(4);
  SalesOrder : abap.char(10);
  SalesOrderItem : abap.numc(6);
  Quantity : abap.quan(13,3);
  BaseUnit : abap.unit(3);
}
