@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Sales Contract Items - Interface'
@Metadata.allowExtensions: true
@ObjectModel.semanticKey: ['SalesContract', 'ContractItem']
//
//  Read model of sales-contract items for mass batch update (replaces
//  ZBATCH_CHANGE). The batch change is the static action updateBatches (see
//  behavior) via the standard sales-document change API.
//
//  VERIFY vbak/vbap fields + the contract document-category filter for your
//  release. Prefer the released I_SalesContract* CDS interfaces where available.
//
define root view entity ZI_Contract_Item
  as select from vbap as item
    inner join vbak as hdr on hdr.vbeln = item.vbeln
{
  key item.vbeln                 as SalesContract,
  key item.posnr                 as ContractItem,
      item.matnr                 as Material,
      item.arktx                 as MaterialDescription,
      item.charg                 as CurrentBatch,
      item.werks                 as Plant
}
where hdr.vbtyp = 'G'   //  'G' = contract - VERIFY for your contract types
