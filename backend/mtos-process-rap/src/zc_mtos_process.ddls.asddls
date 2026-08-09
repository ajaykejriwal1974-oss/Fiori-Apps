@EndUserText.label: 'MTOS Process - Projection'
@AccessControl.authorizationCheck: #CHECK
@Metadata.allowExtensions: true
@Search.searchable: true
@ObjectModel.semanticKey: ['Material', 'Plant', 'SalesOrder', 'SalesOrderItem']
define root view entity ZC_MtosStock
  provider contract transactional_query
  as projection on ZI_MtosStock
{
  key Material,
  key Plant,
  key SalesOrder,
  key SalesOrderItem,
      Quantity,
      BaseUnit
}
