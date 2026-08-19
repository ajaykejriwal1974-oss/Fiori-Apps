@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'MTOS Process (MTO->MTS + Phys Inv) - Interface'
@Metadata.allowExtensions: true
@ObjectModel.semanticKey: ['Material', 'Plant', 'SalesOrder', 'SalesOrderItem']
// Aggregated MSKA (unique V4 key). CompanyCode derived via valuation area (T001K.BWKEY=plant).
define root view entity ZI_MTOS_PROCESS
  as select from nsdm_e_mska as stk
    inner join   mara        as mat on mat.matnr = stk.matnr
    left outer join t001k    as vcc on vcc.bwkey = stk.werks
{
  key stk.matnr  as Material,
  key stk.werks  as Plant,
  key stk.vbeln  as SalesOrder,
  key stk.posnr  as SalesOrderItem,
      sum( cast( stk.kalab as abap.dec( 13, 3 ) ) ) as Quantity,
      mat.meins                                     as BaseUnit,
      vcc.bukrs                                     as CompanyCode
}
group by
  stk.matnr, stk.werks, stk.vbeln, stk.posnr, mat.meins, vcc.bukrs
