@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'HU Item (shared read) - Interface'
@Metadata.allowExtensions: true
// Shared item-level Handling Unit read over the standard HU tables
// (VEPO items inner-join VEKP header). Reused by the item-level HU services
// (packing-detail, goods-movement-hu, hu-unpack) so the join + casts are
// defined ONCE - custom-app audit P3. Read-only basic interface.
define view entity ZI_HU_ItemBase
  as select from vepo as item
    inner join vekp as hu on hu.venum = item.venum
{
  key hu.exidv                                 as HandlingUnit,
  key item.vepos                               as HandlingUnitItem,
      item.matnr                               as Material,
      item.charg                               as Batch,
      cast( item.vemng as abap.quan( 13, 3 ) ) as Quantity,
      item.vemeh                               as Unit,
      item.werks                               as Plant,
      item.lgort                               as StorageLocation
}
