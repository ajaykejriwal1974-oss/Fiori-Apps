@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'MTO to MTS Transfer - Interface'
@Metadata.allowExtensions: true
// Custom transactional service (Route 7) - unmanaged RAP over standard SAP.
// The action(s) call standard BAPIs (see the behavior class TODO).
// VERIFY mska fields/filters against your release before activating.
define root view entity ZI_MtoStock
  as select from mska
{
  key matnr  as Material,
  key werks  as Plant,
  key vbeln  as SalesOrder,
  key posnr  as SalesOrderItem,
      cast( kalab as abap.quan( 13, 3 ) ) as Quantity,
      meins  as BaseUnit
}
