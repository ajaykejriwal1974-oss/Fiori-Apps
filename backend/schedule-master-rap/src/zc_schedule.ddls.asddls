@EndUserText.label: 'Schedule Master - Projection'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
@Search.searchable: true
@ObjectModel.semanticKey: ['ScheduleNumber', 'FiscalYear']
define root view entity ZC_Schedule
  provider contract transactional_query
  as projection on ZI_Schedule
{
      @Search.defaultSearchElement: true
      @UI: { lineItem: [ { position: 10, importance: #HIGH } ], selectionField: [ { position: 10 } ] }
  key ScheduleNumber,
      @UI: { lineItem: [ { position: 20 } ] }
  key FiscalYear,
      @Consumption.valueHelpDefinition: [{ entity: { name: 'ZI_VH_PLANT', element: 'Plant' } }]
      @UI: { lineItem: [ { position: 30, importance: #HIGH } ], selectionField: [ { position: 20 } ] }
      Plant,
      @UI: { lineItem: [ { position: 40 } ] }
      CardNumber,
      @UI: { lineItem: [ { position: 50 } ] }
      ScheduleDate,
      @UI: { lineItem: [ { position: 60 } ] }
      ScheduleTime,
      @Consumption.valueHelpDefinition: [{ entity: { name: 'I_SalesOrder', element: 'SalesOrder' } }]
      @UI: { lineItem: [ { position: 70 } ], selectionField: [ { position: 40 } ] }
      SalesDocument,
      @UI: { lineItem: [ { position: 80 } ] }
      SalesItem,
      @UI: { lineItem: [ { position: 90 } ] }
      DyeingDate,
      @Consumption.valueHelpDefinition: [{ entity: { name: 'I_Product', element: 'Product' } }]
      @UI: { lineItem: [ { position: 100, importance: #HIGH } ], selectionField: [ { position: 30 } ] }
      Material,
      @UI: { lineItem: [ { position: 110 } ] }
      MaterialDesc,
      @UI: { lineItem: [ { position: 120 } ] }
      ScheduleQty,
      @Consumption.valueHelpDefinition: [{ entity: { name: 'I_UnitOfMeasure', element: 'UnitOfMeasure' } }]
      @UI: { lineItem: [ { position: 130 } ] }
      SalesUnit,
      @Consumption.valueHelpDefinition: [{ entity: { name: 'ZC_DD_Shade', element: 'ShadeCode' } }]
      @UI: { lineItem: [ { position: 140 } ], selectionField: [ { position: 50 } ] }
      ShadeCode,
      @UI: { lineItem: [ { position: 150 } ] }
      Remarks,
      @UI: { lineItem: [ { position: 160 } ] }
      CompleteFlag,
      DeletionFlag,
      CreatedBy,
      CreatedOnDate,
      CreatedAtTime,
      LastChangedBy,
      LastChangedDate,
      LastChangedTime
}
