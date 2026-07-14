@EndUserText.label: 'MTOS Process - Projection'
@AccessControl.authorizationCheck: #CHECK
@Metadata.allowExtensions: true
@Search.searchable: true
@ObjectModel.semanticKey: ['Material', 'Plant', 'SalesOrder', 'SalesOrderItem']
define root view entity ZC_MTOS_PROCESS
  provider contract transactional_query
  as projection on ZI_MTOS_PROCESS
{
  key Material,
  key Plant,
  key SalesOrder,
  key SalesOrderItem,
      Quantity,
      BaseUnit
}
