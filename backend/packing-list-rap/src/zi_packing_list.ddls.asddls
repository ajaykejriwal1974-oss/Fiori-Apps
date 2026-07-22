@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Packing List - Interface'
@Metadata.allowExtensions: true
@ObjectModel.semanticKey: ['SalesOrder', 'SalesOrderItem', 'PackListItem', 'BoxNumber']
//
//  Read model for the Packing List (clean-core replacement for the ZPLIST01/02/03
//  family and the ZSD_PACKING_LIST_* programs). ONE model replaces the 14 legacy
//  variants — the plant/format suffixes (A = IPL, T = HSM, N = alt) collapse into
//  a single Plant dimension; Create/Change/Display/Delete become the standard RAP
//  operations + the deletePackingList action (soft-delete to ZPLISTD).
//
//  Sourced from the dispatch table ZSOL_HUDISPATCH (box -> sales order / pack-list
//  linkage), enriched from ZPP_PACK (material / grade / net weight) and ZVBAP
//  (order item). VERIFY the ZPP_PACK year predicate (BOXNO + GJAHR) against your
//  data before activating — see the dispatch-correction read model note.
//
define root view entity ZI_PACKING_LIST
  as select from zsol_hudispatch as disp
    left outer join zpp_pack as pack on  pack.boxno = disp.boxno
    left outer join zvbap    as item on  item.vbeln = disp.so
                                     and item.posnr = disp.so_item
{
  key disp.so                                  as SalesOrder,
  key disp.so_item                             as SalesOrderItem,
  key disp.pck_lst                             as PackListItem,
  key disp.boxno                               as BoxNumber,
      disp.status                              as Status,
      disp.erdat                               as CreatedOnDate,
      disp.time                                as CreatedAtTime,
      item.werks                               as Plant,
      pack.matnr                               as Material,
      pack.grade                               as Grade,
      cast( pack.netwt as abap.dec( 13, 3 ) )  as NetWeight
}
