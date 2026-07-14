@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Gate Pass - Interface (header)'
@Metadata.allowExtensions: true
@ObjectModel.semanticKey: ['GpNumber', 'FiscalYear']
// Managed RAP composition over ZGP_HDR (header) + ZGP_ITEM (items). The inward
// receipt detail ZGP_PART is intentionally NOT part of the composition (it lacks
// the MJAHR key); add it back as a separate read-only entity if needed.
define root view entity ZI_GATEPASS
  as select from zgp_hdr
  composition [0..*] of ZI_GATEPASS_ITEM as _Item
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
