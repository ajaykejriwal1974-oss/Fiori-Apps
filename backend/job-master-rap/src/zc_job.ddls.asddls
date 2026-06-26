@EndUserText.label: 'Job Master - Projection'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
@Search.searchable: true
@ObjectModel.semanticKey: ['JobNumber']
// Value helps reference standard released VH CDS (VERIFY the exact name per
// release); shade fields use the Shade master ZC_DD_Shade.
define root view entity ZC_Job
  provider contract transactional_query
  as projection on ZI_Job
{
  key JobNumber,
      @Search.defaultSearchElement: true
      BatchNumber,
      ScheduleNumber,
      @Consumption.valueHelpDefinition: [{ entity: { name: 'I_PlantStdVH', element: 'Plant' } }]
      Plant,
      DyeingWorkCenter,
      WindingWorkCenter,
      DeletionFlag,
      CreatedBy,
      CreatedOnDate,
      CreatedAtTime,
      LastChangedBy,
      LastChangedDate,
      LastChangedTime
}
