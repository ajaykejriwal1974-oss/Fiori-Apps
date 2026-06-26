@EndUserText.label: 'Sales Orders (close actions) - Projection'
@AccessControl.authorizationCheck: #CHECK
@Metadata.allowExtensions: true
@Search.searchable: true
@ObjectModel.semanticKey: ['SalesOrder']
define root view entity ZC_SalesOrderStatus
  provider contract transactional_query
  as projection on ZI_SalesOrderStatus
{
      @Search.defaultSearchElement: true
  key SalesOrder,
      SalesOrderType,
      SalesOrganization,
      SoldToParty,
      NetValue,
      Currency,
      OverallProcessingStatus,
      CreatedOnDate
}
