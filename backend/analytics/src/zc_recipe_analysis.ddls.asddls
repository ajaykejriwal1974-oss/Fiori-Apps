@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Recipe Master Report'
@Analytics.query: true
@Metadata.allowExtensions: true
define view entity ZC_RecipeAnalysisQuery
  as projection on ZI_RecipeAnalysisCube
{
      @AnalyticsDetails.query.axis: #ROWS
      Plant,
      @AnalyticsDetails.query.axis: #ROWS
      GreyCode,
      @AnalyticsDetails.query.axis: #ROWS
      DyeCode,
      @AnalyticsDetails.query.axis: #FREE
      ShadeCode,
      @AnalyticsDetails.query.axis: #FREE
      ItemNumber,
      @AnalyticsDetails.query.axis: #FREE
      Component,
      @AnalyticsDetails.query.axis: #FREE
      ComponentType,
      SalesUnit,
      @AnalyticsDetails.query.axis: #COLUMNS
      Ratio,
      @AnalyticsDetails.query.axis: #COLUMNS
      RecordCount
}
