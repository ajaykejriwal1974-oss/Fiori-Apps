@EndUserText.label: 'Packing List - Projection'
@AccessControl.authorizationCheck: #CHECK
@Metadata.allowExtensions: true
@Search.searchable: true
@ObjectModel.semanticKey: ['BoxNumber']
define root view entity ZC_PACKING_LIST
  provider contract transactional_query
  as projection on ZI_PACKING_LIST
{
      @Search.defaultSearchElement: true
  key BoxNumber,
  key BoxYear,
      SalesOrder,
      SalesOrderItem,
      PackListItem,
      Plant,
      Material,
      Grade,
      NetWeight,
      PackListDate,
      Status
}
