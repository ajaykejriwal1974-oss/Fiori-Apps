@EndUserText.label: 'Packing List assign - import'
// Instance-action parameter: the box(es) come from the selected instance keys
// (BoxNumber + BoxYear), so only the new assignment values are parameters.
define abstract entity ZD_PACKING_LIST_IMPORT
{
  SalesOrder     : abap.char(10);
  SalesOrderItem : abap.numc(6);
  PackListItem   : abap.numc(6);
}
