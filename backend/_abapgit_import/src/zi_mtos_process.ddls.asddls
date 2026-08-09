@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'MTOS Process (MTO->MTS + Phys Inv) - Interface'
@Metadata.allowExtensions: true
@ObjectModel.semanticKey: ['Material', 'Plant', 'SalesOrder', 'SalesOrderItem']
// Unmanaged RAP over the standard sales-order stock (MSKA). Consolidates the two
// faces of the one legacy program ZSOL_MTOS_PROCESS:
//   - convertToMts    (ZMTOS)  : transfer make-to-order stock to own/MTS stock
//   - createPhysInvDoc (ZHUINV): create the physical-inventory document
// Both actions drive standard BAPIs (see the behavior); no custom persistence.
define root view entity ZI_MTOS_PROCESS
  as select from nsdm_e_mska as stk
    inner join   mara        as mat on mat.matnr = stk.matnr
{
  key stk.matnr  as Material,
  key stk.werks  as Plant,
  key stk.vbeln  as SalesOrder,
  key stk.posnr  as SalesOrderItem,
      cast( stk.kalab as abap.dec( 13, 3 ) ) as Quantity,
      mat.meins  as BaseUnit
}
