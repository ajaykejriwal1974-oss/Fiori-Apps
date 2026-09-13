@EndUserText.label: 'Job Master - Projection'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
@Search.searchable: true
@ObjectModel.semanticKey: ['JobNumber']
// ZJOB01N (MZ_PP_JOB_CARDNI01) offers three F4 helps on this screen; the Fiori
// rewrite shipped with one, on Plant, so an operator had to know the batch, the
// schedule and both work centre codes by heart. The four added below are the
// same three plus the second work centre. Verified 2026-08-30 against the live
// $metadata: only Plant carried a ValueListReferences annotation.
//
// Work centres and the batch bind Plant through additionalBinding, so each list
// narrows to the plant on the job card rather than offering everything in the
// client.
//
// The schedule help points at ZI_Schedule, not ZC_Schedule. ZC_Schedule is a
// transactional_query projection and the F4 service raised UNCAUGHT_EXCEPTION
// when it was used as a value-help entity - tested against the live srvd_f4
// endpoint on 2026-08-30 before this was left in place.
define root view entity ZC_Job
  provider contract transactional_query
  as projection on ZI_Job
{
      @Search.defaultSearchElement: true
      @UI: { lineItem: [ { position: 10, importance: #HIGH } ], selectionField: [ { position: 10 } ] }
  key JobNumber,
      @Consumption.valueHelpDefinition: [ { entity: { name: 'ZI_WIP_BATCH_MGMT', element: 'Batch' },
                                            additionalBinding: [ { localElement: 'Plant', element: 'Plant' } ] } ]
      @UI: { lineItem: [ { position: 20 } ], selectionField: [ { position: 30 } ] }
      BatchNumber,
      @Consumption.valueHelpDefinition: [ { entity: { name: 'ZI_Schedule', element: 'ScheduleNumber' },
                                            additionalBinding: [ { localElement: 'Plant', element: 'Plant' } ] } ]
      @UI: { lineItem: [ { position: 30 } ], selectionField: [ { position: 40 } ] }
      ScheduleNumber,
      @Consumption.valueHelpDefinition: [{ entity: { name: 'ZI_VH_PLANT', element: 'Plant' } }]
      @UI: { lineItem: [ { position: 40, importance: #HIGH } ], selectionField: [ { position: 20 } ] }
      Plant,
      @Consumption.valueHelpDefinition: [ { entity: { name: 'I_WorkCenter', element: 'WorkCenter' },
                                            additionalBinding: [ { localElement: 'Plant', element: 'Plant' } ] } ]
      @UI: { lineItem: [ { position: 50 } ] }
      DyeingWorkCenter,
      @Consumption.valueHelpDefinition: [ { entity: { name: 'I_WorkCenter', element: 'WorkCenter' },
                                            additionalBinding: [ { localElement: 'Plant', element: 'Plant' } ] } ]
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
