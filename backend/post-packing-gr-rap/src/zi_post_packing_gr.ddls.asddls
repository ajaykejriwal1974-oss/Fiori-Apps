@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Post Packing & GR - Interface'
@Metadata.allowExtensions: true
// Custom transactional service (Route 7) - unmanaged RAP over standard SAP.
// The action(s) call standard BAPIs (see the behavior class TODO).
// VERIFY vekp fields/filters against your release before activating.
define root view entity ZI_PostPackGr
  as select from vekp
{
  key exidv    as HandlingUnit,
      vhilm    as PackagingMaterial,
      vpobjkey as Reference
}
