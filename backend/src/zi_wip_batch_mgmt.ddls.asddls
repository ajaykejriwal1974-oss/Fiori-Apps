@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'WIP Batch Close - Interface'
@Metadata.allowExtensions: true
@ObjectModel.semanticKey: ['Batch', 'FiscalYear']
// Transactional view over ZPP_BATCHN for the WIP Batch Close app (zbatch_cls).
// ZI_WIP_BATCH is the analytical cube over the same table and stays read-only;
// this view is the transactional twin that carries the close / reopen action.
// CompanyCode is derived via the valuation area (T001K.BWKEY = plant).
define root view entity ZI_WIP_BATCH_MGMT
  as select from zpp_batchn as bat
    left outer join t001k as vcc on vcc.bwkey = bat.werks
{
  key bat.batchno   as Batch,
  key bat.gjahr     as FiscalYear,
      bat.werks     as Plant,
      vcc.bukrs     as CompanyCode,
      bat.aufnr     as ProductionOrder,
      bat.bchdate   as BatchDate,
      bat.grey_code as GreyMaterial,
      bat.dye_code  as DyedMaterial,
      bat.assigned  as Assigned,
      bat.closed    as Closed,
      @Semantics.quantity.unitOfMeasure: 'BatchUnit'
      bat.qty       as Quantity,
      bat.vrkme     as BatchUnit,
      cast( bat.cheeses as abap.dec( 15, 3 ) ) as Cheeses
}
