@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Merge Analysis - Cube'
@Analytics: { dataCategory: #CUBE, dataExtraction.enabled: true }
@Metadata.allowExtensions: true
// Analytical cube over ZPP_MERGE. Replaces: merge slice of ZBOXSTOCK / ZSSTOCK.
// Old report variants are now dimensions; aggregate in the query.
define view entity ZI_MergeAnalysisCube
  as select from zpp_merge
{
  key aurnr            as Order,
  key grade            as Grade,
  key enduse           as EndUse,
      charg            as Batch,
      shdcd            as ShadeCode,
      @DefaultAggregation: #SUM
      menge            as Quantity,
      @DefaultAggregation: #SUM
      @EndUserText.label: 'Record Count'
      cast( 1 as abap.int4 ) as RecordCount
}
