@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Batch Status - Interface'
@Metadata.allowExtensions: true
// Custom transactional service (Route 7) - unmanaged RAP over standard SAP.
// CompanyCode derived from the plant via the valuation area (T001K.BWKEY = plant,
// valuation at plant level). VERIFY the derived company codes look right.
define root view entity ZI_BATCH_STATUS
  as select from mcha
    left outer join t001k as vcc on vcc.bwkey = mcha.werks
{
  key mcha.matnr  as Material,
  key mcha.werks  as Plant,
  key mcha.charg  as Batch,
      mcha.lwedt  as LastGoodsReceiptDate,
      vcc.bukrs   as CompanyCode
}
