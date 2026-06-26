@EndUserText.label: 'Schedule Master - Projection'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
@Search.searchable: true
@ObjectModel.semanticKey: ['ScheduleNumber', 'FiscalYear']
define root view entity ZC_Schedule
  provider contract transactional_query
  as projection on ZI_Schedule
{
  key ScheduleNumber,
  key FiscalYear,
      @Search.defaultSearchElement: true
      Plant,
      CardNumber,
      ScheduleDate,
      ScheduleTime,
      SalesDocument,
      SalesItem,
      DyeingDate,
      Material,
      MaterialDesc,
      ScheduleQty,
      SalesUnit,
      ShadeCode,
      Remarks,
      CompleteFlag,
      DeletionFlag,
      CreatedBy,
      CreatedOnDate,
      CreatedAtTime,
      LastChangedBy,
      LastChangedDate,
      LastChangedTime
}
