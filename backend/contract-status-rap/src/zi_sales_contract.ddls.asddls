@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Sales Contracts (status actions) - Interface'
@Metadata.allowExtensions: true
@ObjectModel.semanticKey: ['SalesContract']
//
//  Read model + custom lifecycle actions for sales contracts, the clean-core
//  replacement for ZCON_CLOSE / ZCON_CLOSE1 / ZCOREL / ZCON02. Sourced from the
//  standard sales doc header VBAK (contracts: VBTYP = 'G'). The close / complete
//  / release / rate-update logic runs in the behavior (static actions) over the
//  standard sales document - never modifying standard objects.
//
//  VERIFY the contract document-category filter and status fields for your
//  release; prefer the released sales-document CDS interfaces where available.
//
define root view entity ZI_SalesContract
  as select from vbak
{
  key vbeln                                       as SalesContract,
      auart                                       as SalesContractType,
      vkorg                                       as SalesOrganization,
      kunnr                                       as SoldToParty,
      cast( netwr as abap.curr( 15, 2 ) )         as NetValue,
      waerk                                       as Currency,
      gbstk                                       as OverallProcessingStatus,
      erdat                                       as CreatedOnDate
}
where vbtyp = 'G'
