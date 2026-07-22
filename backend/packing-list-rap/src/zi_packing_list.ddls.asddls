@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Packing List - Interface'
@Metadata.allowExtensions: true
@ObjectModel.semanticKey: ['SalesOrder', 'SalesOrderItem', 'PackListItem', 'BoxNumber']
//
//  Read model for the Packing List (clean-core replacement for the ZPLIST01/02/03
//  family and the ZSD_PACKING_LIST_* programs). ONE model replaces the 14 legacy
//  variants — Create / Change / Display / Delete become the standard RAP
//  operations + the deletePackingList action (soft-delete to ZPLISTD).
//
//  Sourced from the dispatch table ZSOL_HUDISPATCH (box -> sales order / pack-list
//  linkage), enriched from ZPP_PACK (material / grade / net weight).
//
//  VERIFY:
//   1. ZPP_PACK join is keyed BOXNO + GJAHR; add the year predicate (or "latest
//      GJAHR") for your data — same note as the dispatch-correction read model.
//   2. Plant (WERKS) — the plant/format variant folding needs a Plant dimension.
//      ZVBAP is not a CDS-selectable transparent table on this system, so source
//      Plant from the confirmed field (ZPP_PACK-WERKS or the delivery header) and
//      add it back below. Left out here so the scaffold activates cleanly.
//
define root view entity ZI_PACKING_LIST
  as select from zsol_hudispatch as disp
    left outer join zpp_pack as pack on pack.boxno = disp.boxno
{
  key disp.so                                  as SalesOrder,
  key disp.so_item                             as SalesOrderItem,
  key disp.pck_lst                             as PackListItem,
  key disp.boxno                               as BoxNumber,
      disp.status                              as Status,
      disp.erdat                               as CreatedOnDate,
      disp.time                                as CreatedAtTime,
      pack.matnr                               as Material,
      pack.grade                               as Grade,
      cast( pack.netwt as abap.dec( 13, 3 ) )  as NetWeight
}
