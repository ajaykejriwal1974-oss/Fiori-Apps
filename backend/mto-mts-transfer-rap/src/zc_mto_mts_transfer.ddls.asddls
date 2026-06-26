@EndUserText.label: 'MTO to MTS Transfer - Projection'
@AccessControl.authorizationCheck: #CHECK
@Metadata.allowExtensions: true
@Search.searchable: true
define root view entity ZC_MtoStock
  provider contract transactional_query
  as projection on ZI_MtoStock
{
  key Material,
  key Plant,
  key SalesOrder,
  key SalesOrderItem,
      Quantity,
      BaseUnit
}
