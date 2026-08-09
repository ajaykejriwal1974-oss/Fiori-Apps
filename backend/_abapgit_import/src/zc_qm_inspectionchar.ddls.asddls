@EndUserText.label: 'QM Open Inspection Char - Projection'
@AccessControl.authorizationCheck: #CHECK
@Metadata.allowExtensions: true
@Search.searchable: true
@ObjectModel.semanticKey: ['InspectionLot', 'InspectionOperation', 'InspectionCharacteristic']
define root view entity ZC_QM_INSPECTIONCHAR
  provider contract transactional_query
  as projection on ZI_QM_INSPECTIONCHAR
{
      @UI: { lineItem: [ { position: 10, importance: #HIGH } ], selectionField: [ { position: 10 } ] }
  key InspectionLot,
      @UI: { lineItem: [ { position: 20 } ] }
  key InspectionOperation,
      @UI: { lineItem: [ { position: 30 } ] }
  key InspectionCharacteristic,
      @Search.defaultSearchElement: true
      @UI: { lineItem: [ { position: 40 } ] }
      CharacteristicDescription,
      @Consumption.valueHelpDefinition: [{ entity: { name: 'I_Product', element: 'Product' } }]
      @UI: { lineItem: [ { position: 50, importance: #HIGH } ], selectionField: [ { position: 20 } ] }
      Material,
      @Consumption.valueHelpDefinition: [{ entity: { name: 'ZI_VH_PLANT', element: 'Plant' } }]
      @UI: { lineItem: [ { position: 60 } ], selectionField: [ { position: 30 } ] }
      Plant,
      @UI: { lineItem: [ { position: 70 } ] }
      Unit,
      @UI: { lineItem: [ { position: 80 } ] }
      ResultValue,
      @UI: { lineItem: [ { position: 90 } ] }
      Valuation,
      @UI: { lineItem: [ { position: 100 } ] }
      InspectionType,
      @UI: { lineItem: [ { position: 110 } ] }
      Origin
}
