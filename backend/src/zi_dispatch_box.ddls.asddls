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
//  erdat in the legacy data can hold invalid calendar values (rendered as "--"
//  by OData V4, which breaks the client list parser) - guard with dats_is_valid
//  so bad dates become null.
//
define root view entity ZI_DISPATCH_BOX
  as select from zsol_hudispatch as disp
    left outer join zpp_pack as pack on pack.boxno = disp.boxno
{
  key disp.boxno                                  as BoxNumber,
      disp.so                                     as SalesOrder,
      disp.so_item                                as SalesOrderItem,
      disp.pck_lst                                as PackListItem,
      disp.status                                 as Status,
      case when dats_is_valid( disp.erdat ) = 1 then disp.erdat
           else cast( '00000000' as abap.dats ) end as CreatedOnDate,
      disp.time                                   as CreatedAtTime,
      pack.matnr                                  as Material,
      pack.grade                                  as Grade,
      cast( pack.netwt as abap.dec( 13, 3 ) )    as NetWeight
}
