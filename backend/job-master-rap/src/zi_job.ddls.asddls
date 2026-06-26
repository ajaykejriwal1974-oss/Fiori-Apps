@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Job Master - Interface'
@Metadata.allowExtensions: true
// Custom master (Route 7) - managed RAP over legacy table ZPP_JOBN (ZJOB01/02/03(N)).
// Field list mirrors the real Z-table (field dictionary). This legacy table
// has no TIMESTAMPL column, so the optimistic-concurrency ETag is omitted
// (add a TIMESTAMPL column to enable it).
define root view entity ZI_Job
  as select from zpp_jobn
{
  key jobno                  as JobNumber,
      batchno                as BatchNumber,
      schno                  as ScheduleNumber,
      werks                  as Plant,
      dye_arbpl              as DyeingWorkCenter,
      win_arbpl              as WindingWorkCenter,
      delind                 as DeletionFlag,
      @Semantics.user.createdBy: true
      ernam                  as CreatedBy,
      erdat                  as CreatedOnDate,
      erzet                  as CreatedAtTime,
      @Semantics.user.lastChangedBy: true
      lastuser               as LastChangedBy,
      lastdate               as LastChangedDate,
      lasttime               as LastChangedTime
}
