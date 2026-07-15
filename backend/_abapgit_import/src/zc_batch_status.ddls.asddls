@EndUserText.label: 'Batch Status - Projection'
@AccessControl.authorizationCheck: #CHECK
@Metadata.allowExtensions: true
@Search.searchable: true
define root view entity ZC_BATCH_STATUS
  provider contract transactional_query
  as projection on ZI_BATCH_STATUS
{
  @Search.defaultSearchElement: true
  key Material,
  key Plant,
  key Batch,
      LastGoodsReceiptDate
}
