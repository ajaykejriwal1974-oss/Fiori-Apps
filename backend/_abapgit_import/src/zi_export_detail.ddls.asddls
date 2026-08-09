@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Export Details Master - Interface'
@Metadata.allowExtensions: true
// Custom master (Route 7) - managed RAP over legacy table ZEXP (ZMBR2).
// Field list mirrors the real Z-table (field dictionary). This legacy table
// has no TIMESTAMPL column, so the optimistic-concurrency ETag is omitted
// (add a TIMESTAMPL column to enable it). Code fields carry in-table text
// (@ObjectModel.text.element) and value helps (on the projection).
define root view entity ZI_EXPORT_DETAIL
  as select from zexp
{
  key vbeln                  as BillingDocument,
  key kschl                  as ConditionType,
      cast(netwr as abap.dec(23,2)) as NetValue,
      waerk                  as Currency,
      cast(kursk as abap.dec(9,5)) as ExchangeRate,
      fkdat                  as BillingDate
}
