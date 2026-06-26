@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Palletization - Interface'
@Metadata.allowExtensions: true
// Custom transactional service (Route 7) - unmanaged RAP over standard SAP.
// The action(s) call standard BAPIs (see the behavior class TODO).
// VERIFY vekp fields/filters against your release before activating.
define root view entity ZI_Pallet
  as select from vekp
{
  key exidv    as Pallet,
      vhilm    as PackagingMaterial,
      vpobjkey as Reference,
      cast( ntgew as abap.quan( 15, 3 ) ) as NetWeight,
      gewei    as WeightUnit
}
