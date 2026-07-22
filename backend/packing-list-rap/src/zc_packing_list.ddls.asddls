@EndUserText.label: 'Packing List - Projection'
@AccessControl.authorizationCheck: #CHECK
@Metadata.allowExtensions: true
@Search.searchable: true
@ObjectModel.semanticKey: ['SalesOrder', 'SalesOrderItem', 'PackListItem', 'BoxNumber']
define root view entity ZC_PACKING_LIST
  provider contract transactional_query
  as projection on ZI_PACKING_LIST
{
      @Search.defaultSearchElement: true
  key SalesOrder,
  key SalesOrderItem,
  key PackListItem,
      @Search.defaultSearchElement: true
  key BoxNumber,
      Status,
      CreatedOnDate,
      CreatedAtTime,
      Plant,
      Material,
      Grade,
      NetWeight
}
