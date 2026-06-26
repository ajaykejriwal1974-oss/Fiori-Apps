@EndUserText.label: 'Schedule Master - Projection'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
@Search.searchable: true
@ObjectModel.semanticKey: ['ScheduleNumber', 'FiscalYear']
// Value helps reference standard released VH CDS (VERIFY the exact name per
// release); shade fields use the Shade master ZC_DD_Shade.
define root view entity ZC_Schedule
  provider contract transactional_query
  as projection on ZI_Schedule
{
  key ScheduleNumber,
  key FiscalYear,
      @Search.defaultSearchElement: true
      @Consumption.valueHelpDefinition: [{ entity: { name: 'I_PlantStdVH', element: 'Plant' } }]
      Plant,
      CardNumber,
      ScheduleDate,
      ScheduleTime,
      SalesDocument,
      SalesItem,
      DyeingDate,
      @Consumption.valueHelpDefinition: [{ entity: { name: 'I_MaterialStdVH', element: 'Material' } }]
      Material,
      MaterialDesc,
      ScheduleQty,
      @Consumption.valueHelpDefinition: [{ entity: { name: 'I_UnitOfMeasureStdVH', element: 'UnitOfMeasure' } }]
      SalesUnit,
      @Consumption.valueHelpDefinition: [{ entity: { name: 'ZC_DD_Shade', element: 'ShadeCode' } }]
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
