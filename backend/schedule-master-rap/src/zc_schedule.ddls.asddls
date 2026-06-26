@EndUserText.label: 'Schedule Master - Projection'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
@Search.searchable: true
@ObjectModel.semanticKey: ['ScheduleId']
define root view entity ZC_Schedule
  provider contract transactional_query
  as projection on ZI_Schedule
{
  key ScheduleId,
      @Search.defaultSearchElement: true
      ScheduleDate,
      Material,
      Quantity,
      Plant,
      ScheduleStatus,
      IsActive,
      CreatedBy,
      CreatedAt,
      LastChangedBy,
      LastChangedAt,
      LocalLastChangedAt
}
