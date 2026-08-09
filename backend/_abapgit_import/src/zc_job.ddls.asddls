@EndUserText.label: 'Job Master - Projection'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
@Search.searchable: true
@ObjectModel.semanticKey: ['JobNumber']
define root view entity ZC_Job
  provider contract transactional_query
  as projection on ZI_Job
{
      @Search.defaultSearchElement: true
      @UI: { lineItem: [ { position: 10, importance: #HIGH } ], selectionField: [ { position: 10 } ] }
  key JobNumber,
      @UI: { lineItem: [ { position: 20 } ], selectionField: [ { position: 30 } ] }
      BatchNumber,
      @UI: { lineItem: [ { position: 30 } ], selectionField: [ { position: 40 } ] }
      ScheduleNumber,
      @Consumption.valueHelpDefinition: [{ entity: { name: 'ZI_VH_PLANT', element: 'Plant' } }]
      @UI: { lineItem: [ { position: 40, importance: #HIGH } ], selectionField: [ { position: 20 } ] }
      Plant,
      @UI: { lineItem: [ { position: 50 } ] }
      DyeingWorkCenter,
      @UI: { lineItem: [ { position: 60 } ] }
      WindingWorkCenter,
      @UI: { lineItem: [ { position: 70 } ] }
      DeletionFlag,
      CreatedBy,
      CreatedOnDate,
      CreatedAtTime,
      LastChangedBy,
      LastChangedDate,
      LastChangedTime
}
