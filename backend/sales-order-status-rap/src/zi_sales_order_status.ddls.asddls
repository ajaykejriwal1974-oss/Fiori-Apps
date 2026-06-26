@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Sales Orders (close actions) - Interface'
@Metadata.allowExtensions: true
@ObjectModel.semanticKey: ['SalesOrder']
//
//  Read model + close actions for sales orders, the clean-core replacement for
//  ZSOCLOSE / ZSOCLOSE1 (ZSOL_SALESORDER_CLOSE / ZSOL_SO_CLOSE). Sourced from
//  the standard sales-document header VBAK (orders: VBTYP = 'C'). The close
//  logic runs in the behavior (static actions) over the standard sales document.
//
//  VERIFY the order document-category filter / status fields for your release.
//
define root view entity ZI_SalesOrderStatus
  as select from vbak
{
  key vbeln                                       as SalesOrder,
      auart                                       as SalesOrderType,
      vkorg                                       as SalesOrganization,
      kunnr                                       as SoldToParty,
      cast( netwr as abap.curr( 15, 2 ) )         as NetValue,
      waerk                                       as Currency,
      gbstk                                       as OverallProcessingStatus,
      erdat                                       as CreatedOnDate
}
where vbtyp = 'C'
