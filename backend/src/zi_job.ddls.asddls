@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Job Master - Interface'
@Metadata.allowExtensions: true
// Custom master (Route 7) - managed RAP over legacy table ZPP_JOBN (ZJOB01/02/03(N)).
// Field list mirrors the real Z-table (field dictionary). This legacy table
// has no TIMESTAMPL column, so the optimistic-concurrency ETag is omitted
// (add a TIMESTAMPL column to enable it). Code fields carry in-table text
// (@ObjectModel.text.element) and value helps (on the projection).
//
// Soft-deleted job cards are filtered out. ZJOB01N deletes by setting
// DELIND = 'X' and this view had no filter, so 24 of the 131,340 job cards in
// KSD - deleted in the GUI - were still listed in the app (measured
// 2026-08-30).
//
// The filter and the read-only DeletionFlag in the behaviour definition go
// together and must be activated together. Filtering alone, with the flag still
// editable, means a user who types 'X' into it saves a row that then vanishes
// from under the managed runtime's re-read. Deletion goes through the
// markDeleted action instead.
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
where
  delind <> 'X'
