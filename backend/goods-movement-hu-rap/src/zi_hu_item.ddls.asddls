@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Handling Unit Items - Interface'
@Metadata.allowExtensions: true
@ObjectModel.semanticKey: ['HandlingUnit', 'HandlingUnitItem']
//
//  Read model for box / HU-wise goods movement (replaces ZBOX_MOVE).
//  Sourced from the standard HU dictionary (VEKP header / VEPO items).
//  The goods movement itself is posted by the static action postGoodsMovement
//  (see the behavior) through BAPI_GOODSMVT_CREATE - not persisted here.
//
//  VERIFY field/table names against your release before activating.
//
define root view entity ZI_HU_Item
  as select from vepo as item
    inner join vekp as hu on hu.venum = item.venum
{
  key hu.exidv                                    as HandlingUnit,
  key item.vepos                                  as HandlingUnitItem,
      item.matnr                                  as Material,
      item.charg                                  as Batch,
      cast( item.vemng as abap.quan( 13, 3 ) )    as Quantity,
      item.vemeh                                  as Unit,
      item.werks                                  as Plant,
      item.lgort                                  as StorageLocation
}
