@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Gate Pass Header - Interface'
@Metadata.allowExtensions: true
@ObjectModel.semanticKey: ['GpNumber', 'FiscalYear']
// Flat managed BO over ZGP_HDR (no composition). Items are a separate flat BO
// (ZI_GTPASS_ITEM) exposed by the same service.
define root view entity ZI_GTPASS
  as select from zgp_hdr
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
      erzet                  as CreatedAtTime
}
