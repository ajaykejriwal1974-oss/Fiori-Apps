@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Sales Register - Cube'
@Analytics: { dataCategory: #CUBE, dataExtraction.enabled: true }
@Metadata.allowExtensions: true
// Analytical cube for the Sales Register. Replaces ZSALES (ZCRPT_SD_001),
// ZSALESN (ZSD_SALES_RPT_NEW), ZSALESB and the sales side of ZSOREG (order register).
// Item-level over standard billing VBRK (header) + VBRP (item). The old report
// variants (sales report / order register / branch) are dimensions here.
// Amounts/quantities are cast to plain decimals (no external currency/unit ref).
define view entity ZI_SALES_REGISTER
  as select from vbrk
    inner join vbrp on vbrk.vbeln = vbrp.vbeln
{
  key vbrk.vbeln                          as BillingDocument,
  key vbrp.posnr                          as BillingItem,
      vbrk.fkart                          as BillingType,
      vbrk.fkdat                          as BillingDate,
      vbrk.vkorg                          as SalesOrganization,
      vbrk.bukrs                          as CompanyCode,
      vbrk.kunag                          as SoldToParty,
      vbrk.kunrg                          as Payer,
      vbrk.fksto                          as Cancelled,
      vbrk.waerk                          as Currency,
      vbrp.matnr                          as Material,
      vbrp.arktx                          as MaterialText,
      vbrp.werks                          as Plant,
      vbrp.aubel                          as SalesOrder,
      vbrp.vrkme                          as SalesUnit,
      @DefaultAggregation: #SUM
      cast( vbrp.fkimg as abap.dec( 15, 3 ) ) as BilledQuantity,
      @DefaultAggregation: #SUM
      cast( vbrp.netwr as abap.dec( 15, 2 ) ) as NetValue,
      @DefaultAggregation: #SUM
      cast( vbrp.mwsbp as abap.dec( 15, 2 ) ) as TaxAmount,
      @DefaultAggregation: #SUM
      @EndUserText.label: 'Record Count'
      cast( 1 as abap.int4 )              as RecordCount
}
