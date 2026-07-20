@EndUserText.label: 'Dispatch Boxes - Projection'
@AccessControl.authorizationCheck: #CHECK
@Metadata.allowExtensions: true
@Search.searchable: true
@ObjectModel.semanticKey: ['BoxNumber']
define root view entity ZC_DISPATCH_BOX
  provider contract transactional_query
  as projection on ZI_DISPATCH_BOX
{
      @Search.defaultSearchElement: true
  key BoxNumber,
      SalesOrder,
      SalesOrderItem,
      PackListItem,
      Status,
      CreatedOnDate,
      CreatedAtTime,
      Material,
      Grade,
      NetWeight
}
