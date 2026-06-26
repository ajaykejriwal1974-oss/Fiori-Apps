@EndUserText.label: 'Batch Status - Projection'
@AccessControl.authorizationCheck: #CHECK
@Metadata.allowExtensions: true
@Search.searchable: true
define root view entity ZC_BatchStatus
  provider contract transactional_query
  as projection on ZI_BatchStatus
{
  key Material,
  key Plant,
  key Batch,
      LastGoodsReceiptDate
}
