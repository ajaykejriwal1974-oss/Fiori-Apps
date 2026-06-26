@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Merge Details Master - Interface'
@Metadata.allowExtensions: true
// Custom master (Route 7) - managed RAP over legacy table ZPP_MERGE (ZMERGE).
// Field list mirrors the real Z-table (field dictionary). This legacy table
// has no TIMESTAMPL column, so the optimistic-concurrency ETag is omitted
// (add a TIMESTAMPL column to enable it).
define root view entity ZI_Merge
  as select from zpp_merge
{
  key aurnr                  as OrderNumber,
  key grade                  as Grade,
  key enduse                 as EndUse,
      charg                  as Batch,
      shdcd                  as ShadeCode,
      menge                  as Quantity,
      shdcd2                 as ShadeCode2
}
