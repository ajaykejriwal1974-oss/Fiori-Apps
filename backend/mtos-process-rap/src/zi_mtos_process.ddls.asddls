@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'MTOS Process (MTO->MTS + Phys Inv) - Interface'
@Metadata.allowExtensions: true
@ObjectModel.semanticKey: ['Material', 'Plant', 'SalesOrder', 'SalesOrderItem']
// Unmanaged RAP over the standard sales-order stock (MSKA). Consolidates the two
// faces of the one legacy program ZSOL_MTOS_PROCESS:
//   - convertToMts    (ZMTOS)  : transfer make-to-order stock to own/MTS stock
//   - createPhysInvDoc (ZHUINV): create the physical-inventory document
// Both actions drive standard BAPIs (see the behavior); no custom persistence.
define root view entity ZI_MtosStock
  as select from mska
{
  key matnr  as Material,
  key werks  as Plant,
  key vbeln  as SalesOrder,
  key posnr  as SalesOrderItem,
      @Semantics.quantity.unitOfMeasure: 'BaseUnit'
      cast( kalab as abap.quan( 13, 3 ) ) as Quantity,
      @Semantics.unitOfMeasure: true
      meins  as BaseUnit
}
