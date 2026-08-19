@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'TDS (Withholding Tax) Register - Cube'
@Analytics: { dataCategory: #CUBE, dataExtraction.enabled: true }
@Metadata.allowExtensions: true
// Analytical cube for the TDS / withholding-tax register. Replaces ZFI_TDS
// (ZFI_RPT_TDS, vendor+customer TDS) and ZQTDS (ZRPT_FI_INMIS, quarterly TDS) over
// the standard withholding-tax line-item table WITH_ITEM. Old vendor / customer /
// quarterly variants become dimensions (WithholdingTaxType, period on PostingDate).
// Amounts cast to plain decimals (local company-code currency).
// VERIFY: vendor/customer (LIFNR/KUNNR) live on the FI line BSEG - join on
// bukrs/belnr/gjahr/buzei if the register must show the business partner.
define view entity ZI_TDS
  as select from with_item
{
  key bukrs                               as CompanyCode,
  key belnr                               as AccountingDocument,
  key gjahr                               as FiscalYear,
  key buzei                               as LineItem,
  key witht                               as WithholdingTaxType,
      wt_withcd                           as WithholdingTaxCode,
      @DefaultAggregation: #SUM
      cast( wt_qsshb as abap.dec( 15, 2 ) ) as WithholdingBaseAmount,
      @DefaultAggregation: #SUM
      cast( wt_qbshb as abap.dec( 15, 2 ) ) as WithholdingTaxAmount,
      @DefaultAggregation: #SUM
      @EndUserText.label: 'Record Count'
      cast( 1 as abap.int4 )              as RecordCount
}
