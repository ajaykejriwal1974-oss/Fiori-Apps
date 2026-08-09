@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Recipe Master Report - Cube'
@Analytics: { dataCategory: #CUBE, dataExtraction.enabled: true }
@Metadata.allowExtensions: true
// Analytical cube over ZPP_RECEIPE. Replaces: ZRECPM.
// Old report variants are now dimensions; aggregate in the query.
define view entity ZI_RecipeAnalysisCube
  as select from zpp_receipe
{
  key werks            as Plant,
  key grey_code        as GreyCode,
  key dye_code         as DyeCode,
  key shdcd            as ShadeCode,
  key posnr            as ItemNumber,
      component        as Component,
      comp_type        as ComponentType,
      @DefaultAggregation: #SUM
      @Semantics.quantity.unitOfMeasure: 'SalesUnit'
      ratio            as Ratio,
      @Semantics.unitOfMeasure: true
      vrkme            as SalesUnit,
      @DefaultAggregation: #SUM
      @EndUserText.label: 'Record Count'
      cast( 1 as abap.int4 ) as RecordCount
}
