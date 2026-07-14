@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Gate Pass - Interface (header)'
@Metadata.allowExtensions: true
@ObjectModel.semanticKey: ['GpNumber', 'FiscalYear']
// Custom gate-pass object (no standard SAP equivalent) - managed RAP composition
// over the real legacy tables ZGP_HDR (header) and ZGP_ITEM (items). Models the
// ZGPS01/02/03 (outward) and ZGPSI1/2/3 (inward) entry transactions. The gate-pass
// number comes from number-range object via ZGPASS_NUM (wire in the determination).
define root view entity ZI_GatePass
  as select from zgp_hdr
  composition [0..*] of ZI_GatePassItem as _Item
{
  key gpnum                  as GpNumber,
  key mjahr                  as FiscalYear,
      dtype                  as DocumentType,
      werks                  as Plant,
      dept                   as Department,
      vhnum                  as VehicleNumber,
      gindat                 as InDate,
      gintme                 as InTime,
      gotdat                 as OutDate,
      gottme                 as OutTime,
      remks                  as Remarks,
      cre_user               as CreatedByUser,
      @Semantics.user.createdBy: true
      ernam                  as CreatedBy,
      erdat                  as CreatedOnDate,
      erzet                  as CreatedAtTime,
      _Item
}
