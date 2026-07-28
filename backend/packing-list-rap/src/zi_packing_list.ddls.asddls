@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Packing List - Interface'
@Metadata.allowExtensions: true
@ObjectModel.semanticKey: ['BoxNumber']
//
//  Read model for the Packing List — sourced from ZPP_PACK (the box table), the
//  SAME table the create/change/delete actions update (the PKLST assignment).
//  This replaces the earlier ZSOL_HUDISPATCH source so the worklist shows exactly
//  the boxes the actions operate on. Mirrors the legacy ZSD_PACKING_LIST_01, which
//  reads its boxes from ZPP_PACK.
//
//  Key = the box: BoxNumber (boxno) + BoxYear (gjahr) is the ZPP_PACK primary key.
//  SalesOrder / SalesOrderItem / PackListItem are the current assignment (blank
//  when the box is not yet on a packing list); Status is derived P (packed) / O (open).
//
define root view entity ZI_PACKING_LIST
  as select from zpp_pack as pack
{
  key pack.boxno                               as BoxNumber,
  key pack.gjahr                               as BoxYear,
      pack.vbeln                               as SalesOrder,
      pack.posnr                               as SalesOrderItem,
      pack.pklst                               as PackListItem,
      pack.werks                               as Plant,
      pack.matnr                               as Material,
      pack.grade                               as Grade,
      cast( pack.netwt as abap.dec( 13, 3 ) )  as NetWeight,
      pack.pldate                              as PackListDate,
      cast( case when pack.pklst is not initial then 'P' else 'O' end as abap.char( 1 ) ) as Status
}
