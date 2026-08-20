@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Production Confirmation - Interface'
@Metadata.allowExtensions: true
@ObjectModel.semanticKey: ['ConfirmationNumber', 'ConfirmationCounter']
// Order confirmations (AFRU) enriched with order header (AFKO) and the
// company code derived from the valuation area (T001K.BWKEY = plant).
// STOKZ = 'X' marks the reversal document itself - excluded, only the
// original confirmations are offered for cancellation.
// STZHL <> 0 means this confirmation has already been cancelled.
define root view entity ZI_PROD_CONFIRMATION
  as select from afru
    left outer join afko  as ord on ord.aufnr = afru.aufnr
    left outer join t001k as vcc on vcc.bwkey = afru.werks
{
  key afru.rueck                                 as ConfirmationNumber,
  key afru.rmzhl                                 as ConfirmationCounter,
      afru.aufnr                                 as OrderNumber,
      afru.vornr                                 as OperationNumber,
      afru.werks                                 as Plant,
      vcc.bukrs                                  as CompanyCode,
      ord.plnbez                                 as Material,
      afru.budat                                 as PostingDate,
      afru.isdd                                  as ExecutionStartDate,
      @Semantics.quantity.unitOfMeasure: 'ConfirmationUnit'
      afru.gmnga                                 as YieldQuantity,
      @Semantics.quantity.unitOfMeasure: 'ConfirmationUnit'
      afru.xmnga                                 as ScrapQuantity,
      afru.gmein                                 as ConfirmationUnit,
      afru.stzhl                                 as ReversalCounter,
      case when afru.stzhl <> 0
           then cast('X' as abap.char(1))
           else cast('' as abap.char(1))
      end                                        as IsCancelled,
      afru.ernam                                 as CreatedBy,
      afru.ersda                                 as CreatedOn
}
where afru.stokz = ''
