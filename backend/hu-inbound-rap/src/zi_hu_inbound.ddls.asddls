@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Inbound Delivery HUs - Interface'
@Metadata.allowExtensions: true
// Header-level read via the shared HU base (audit P3). postInboundGr action on
// the behavior (replaces ZSOL_INBOUND_HU / ZHUINB).
define root view entity ZI_InboundHu
  as select from ZI_HU_HeaderBase
{
  key HandlingUnit,
      Reference as InboundDelivery,
      PackagingMaterial
}
