@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'MTOS Process (MTO->MTS + Phys Inv) - Interface'
@Metadata.allowExtensions: true
@ObjectModel.semanticKey: ['Material', 'Plant', 'SalesOrder', 'SalesOrderItem']
// Unmanaged RAP over the standard sales-order stock (MSKA). Consolidates the two
// faces of the one legacy program ZSOL_MTOS_PROCESS:
//   - convertToMts    (ZMTOS)  : transfer make-to-order stock to own/MTS stock
//   - createPhysInvDoc (ZHUINV): create the physical-inventory document
// Both actions drive standard BAPIs (see the behavior); no custom persistence.
// MSKA holds one row per storage location / batch, so the raw rows are NOT unique
// on (Material,Plant,SalesOrder,SalesOrderItem). Aggregate the valuated stock to a
// single row per sales-order item so the OData V4 key is unique.
define root view entity ZI_MTOS_PROCESS
  as select from nsdm_e_mska as stk
    inner join   mara        as mat on mat.matnr = stk.matnr
{
  key stk.matnr  as Material,
  key stk.werks  as Plant,
  key stk.vbeln  as SalesOrder,
  key stk.posnr  as SalesOrderItem,
      sum( cast( stk.kalab as abap.dec( 13, 3 ) ) ) as Quantity,
      mat.meins                                     as BaseUnit
}
group by
  stk.matnr,
  stk.werks,
  stk.vbeln,
  stk.posnr,
  mat.meins
