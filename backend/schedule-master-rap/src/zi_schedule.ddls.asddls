@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Schedule Master - Interface'
@Metadata.allowExtensions: true
// Custom master (Route 7) - managed RAP over legacy table ZPP_SCHEDULEN (ZSCH01/02/03(N)).
// Field list mirrors the real Z-table (field dictionary). This legacy table
// has no TIMESTAMPL column, so the optimistic-concurrency ETag is omitted
// (add a TIMESTAMPL column to enable it). Code fields carry in-table text
// (@ObjectModel.text.element) and value helps (on the projection).
define root view entity ZI_Schedule
  as select from zpp_schedulen
{
  key schno                  as ScheduleNumber,
  key gjahr                  as FiscalYear,
      werks                  as Plant,
      kdno                   as CardNumber,
      schdt                  as ScheduleDate,
      schtime                as ScheduleTime,
      vbeln                  as SalesDocument,
      posnr                  as SalesItem,
      dyedt                  as DyeingDate,
      @ObjectModel.text.element: ['MaterialDesc']
      matnr                  as Material,
      @Semantics.text: true
      maktx                  as MaterialDesc,
      @Semantics.quantity.unitOfMeasure: 'SalesUnit'
      sch_qty                as ScheduleQty,
      @Semantics.unitOfMeasure: true
      vrkme                  as SalesUnit,
      shdcd                  as ShadeCode,
      remarks                as Remarks,
      complete               as CompleteFlag,
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
