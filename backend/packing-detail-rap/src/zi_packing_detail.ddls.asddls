@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Packing Details - Interface'
@Metadata.allowExtensions: true
// Custom transactional service (Route 7) - unmanaged RAP over standard SAP.
// The action(s) call standard BAPIs (see the behavior class TODO).
// VERIFY vepo as item
    inner join vekp as hu on hu.venum = item.venum fields/filters against your release before activating.
define root view entity ZI_PackingItem
  as select from vepo as item
    inner join vekp as hu on hu.venum = item.venum
{
  key hu.exidv   as HandlingUnit,
  key item.vepos as HandlingUnitItem,
      item.matnr as Material,
      item.charg as Batch,
      cast( item.vemng as abap.quan( 13, 3 ) ) as Quantity,
      item.vemeh as Unit
}
