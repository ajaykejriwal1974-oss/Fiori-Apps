@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Export Details Master - Interface'
@Metadata.allowExtensions: true
// Custom master (Route 7) - managed RAP over legacy table ZEXP (ZMBR2).
// Field list mirrors the real Z-table (field dictionary). This legacy table
// has no TIMESTAMPL column, so the optimistic-concurrency ETag is omitted
// (add a TIMESTAMPL column to enable it). Code fields carry in-table text
// (@ObjectModel.text.element) and value helps (on the projection).
define root view entity ZI_ExportDetail
  as select from zexp
{
  key vbeln                  as BillingDocument,
  key kschl                  as ConditionType,
      @Semantics.amount.currencyCode: 'Currency'
      netwr                  as NetValue,
      @Semantics.currencyCode: true
      waerk                  as Currency,
      kursk                  as ExchangeRate,
      fkdat                  as BillingDate
}
