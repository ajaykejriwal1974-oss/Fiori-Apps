@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Job Card Report - Cube'
@Analytics: { dataCategory: #CUBE, dataExtraction.enabled: true }
@Metadata.allowExtensions: true
// Analytical cube over ZPP_JOBN. Replaces: ZJOBREPTN (ZJOBREPORT retired).
// Old report variants are now dimensions; aggregate in the query.
define view entity ZI_JobCardCube
  as select from zpp_jobn
{
  key jobno            as JobNumber,
      batchno          as Batch,
      schno            as ScheduleNumber,
      werks            as Plant,
      dye_arbpl        as DyeingWorkCenter,
      win_arbpl        as WindingWorkCenter,
      delind           as DeletionFlag,
      @DefaultAggregation: #SUM
      @EndUserText.label: 'Record Count'
      cast( 1 as abap.int4 ) as RecordCount
}
