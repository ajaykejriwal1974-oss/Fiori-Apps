@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Sales Document Status - Interface'
@Metadata.allowExtensions: true
@ObjectModel.semanticKey: ['SalesDocument']
// Unmanaged RAP over the standard sales-document header VBAK. Consolidates the
// two former services (contract-status-rap + sales-order-status-rap), whose read
// models were identical bar the VBTYP filter. DocumentCategory ('G' contract /
// 'C' order) is a dimension; the lifecycle actions cover both:
//   contracts : closeContract / completeContract / releaseContract / updatePendingRate
//   orders    : closeSalesOrder / closeOrderProgram
// All actions drive the standard sales document via BAPI_SD_SALESDOCUMENT_CHANGE.
define root view entity ZI_SalesDocStatus
  as select from vbak
{
  key vbeln                                       as SalesDocument,
      vbtyp                                       as DocumentCategory,
      auart                                       as SalesDocumentType,
      vkorg                                       as SalesOrganization,
      kunnr                                       as SoldToParty,
      cast( netwr as abap.curr( 15, 2 ) )         as NetValue,
      waerk                                       as Currency,
      gbstk                                       as OverallProcessingStatus,
      erdat                                       as CreatedOnDate
}
where vbtyp = 'C' or vbtyp = 'G'
