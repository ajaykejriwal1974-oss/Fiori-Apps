@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Inbound Delivery HUs - Interface'
@Metadata.allowExtensions: true
// Custom transactional service (Route 7) - unmanaged RAP over standard SAP.
// The action(s) call standard BAPIs (see the behavior class TODO).
// VERIFY vekp fields/filters against your release before activating.
define root view entity ZI_InboundHu
  as select from vekp
{
  key exidv    as HandlingUnit,
      vpobjkey as InboundDelivery,
      vhilm    as PackagingMaterial
}
