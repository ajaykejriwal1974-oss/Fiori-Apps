@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'HU Physical Inventory - Interface'
@Metadata.allowExtensions: true
// Custom transactional service (Route 7) - unmanaged RAP over standard SAP.
// The action(s) call standard BAPIs (see the behavior class TODO).
// VERIFY vekp fields/filters against your release before activating.
define root view entity ZI_HuPhysInv
  as select from vekp
{
  key exidv    as HandlingUnit,
      vpobjkey as Reference,
      vhilm    as PackagingMaterial
}
