@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Batch Status - Interface'
@Metadata.allowExtensions: true
// Custom transactional service (Route 7) - unmanaged RAP over standard SAP.
// The action(s) call standard BAPIs (see the behavior class TODO).
// VERIFY mcha fields/filters against your release before activating.
define root view entity ZI_BatchStatus
  as select from mcha
{
  key matnr  as Material,
  key werks  as Plant,
  key charg  as Batch,
      lwedt  as LastGoodsReceiptDate
}
