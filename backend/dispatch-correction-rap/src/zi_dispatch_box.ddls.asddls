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
//  NOTE: ZPP_PACK is keyed by BOXNO + GJAHR; the join below may need the year
//  predicate (or "latest GJAHR") for your data - VERIFY before activating.
//
define root view entity ZI_DispatchBox
  as select from zsol_hudispatch as disp
    left outer join zpp_pack as pack on pack.boxno = disp.boxno
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
      cast( pack.netwt as abap.quan( 13, 3 ) )    as NetWeight
}
