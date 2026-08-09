@EndUserText.label: 'Gate Pass Header - Projection'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
@Search.searchable: true
@ObjectModel.semanticKey: ['GpNumber', 'FiscalYear']
define root view entity ZC_GTPASS
  provider contract transactional_query
  as projection on ZI_GTPASS
{
      @Search.defaultSearchElement: true
      @UI: { lineItem: [ { position: 10, importance: #HIGH } ], selectionField: [ { position: 10 } ] }
  key GpNumber,
      @UI: { lineItem: [ { position: 20 } ] }
  key FiscalYear,
      @UI: { lineItem: [ { position: 30 } ], selectionField: [ { position: 30 } ] }
      DocumentType,
      @Consumption.valueHelpDefinition: [{ entity: { name: 'ZI_VH_PLANT', element: 'Plant' } }]
      @UI: { lineItem: [ { position: 40, importance: #HIGH } ], selectionField: [ { position: 20 } ] }
      Plant,
      @UI: { lineItem: [ { position: 50 } ] }
      Department,
      @UI: { lineItem: [ { position: 60 } ] }
      VehicleNumber,
      @UI: { lineItem: [ { position: 70 } ] }
      InDate,
      @UI: { lineItem: [ { position: 80 } ] }
      InTime,
      @UI: { lineItem: [ { position: 90 } ] }
      OutDate,
      @UI: { lineItem: [ { position: 100 } ] }
      OutTime,
      @UI: { lineItem: [ { position: 110 } ] }
      Remarks,
      @UI: { lineItem: [ { position: 120 } ] }
      CreatedByUser,
      CreatedBy,
      @UI: { lineItem: [ { position: 130 } ] }
      CreatedOnDate,
      CreatedAtTime
}
