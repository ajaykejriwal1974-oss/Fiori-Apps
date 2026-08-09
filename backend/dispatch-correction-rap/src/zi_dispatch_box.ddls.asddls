@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Dispatch Boxes - Interface'
@Metadata.allowExtensions: true
@ObjectModel.semanticKey: ['BoxNumber']
//
//  Read model for dispatch correction (replaces ZDSP_CORR / ZSOL_DISPATCH_CORRECTION).
//  Sourced from the existing custom dispatch table ZSOL_HUDISPATCH, reusing the
//  packing table ZPP_PACK for box detail (material / grade / net weight).
//  The correction itself is applied by the static action correctDispatch (see
//  the behavior) - it re-assigns the box's sales order / item / status.
//
//  NOTE: ZPP_PACK is keyed by BOXNO + GJAHR and the dispatch table has no year, so
//  the pack join goes through ZI_PackLatestYear (latest GJAHR per box) — a bare BOXNO
//  join would fan each dispatch row out once per fiscal year and collide the
//  declared "key boxno". VERIFY "latest year" is the right pick for your data.
//
define root view entity ZI_DISPATCH_BOX
  as select from zsol_hudispatch as disp
    left outer join ZI_PackLatestYear as latest on latest.boxno = disp.boxno
    left outer join zpp_pack as pack on  pack.boxno = disp.boxno
                                     and pack.gjahr = latest.LatestYear
{
  key disp.boxno                                  as BoxNumber,
      disp.so                                     as SalesOrder,
      disp.so_item                                as SalesOrderItem,
      disp.pck_lst                                as PackListItem,
      disp.status                                 as Status,
      disp.erdat                                  as CreatedOnDate,
      disp.time                                   as CreatedAtTime,
      pack.matnr                                  as Material,
      pack.grade                                  as Grade,
      cast( pack.netwt as abap.dec( 13, 3 ) )    as NetWeight
}
