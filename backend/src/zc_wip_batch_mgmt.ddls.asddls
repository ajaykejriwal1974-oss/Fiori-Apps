@EndUserText.label: 'WIP Batch Close - Projection'
@AccessControl.authorizationCheck: #CHECK
@Metadata.allowExtensions: true
@Search.searchable: true
define root view entity ZC_WIP_BATCH_MGMT
  provider contract transactional_query
  as projection on ZI_WIP_BATCH_MGMT
{
      @Search.defaultSearchElement: true
      @UI: { lineItem: [ { position: 10, importance: #HIGH } ], selectionField: [ { position: 20 } ] }
  key Batch,
      @UI: { lineItem: [ { position: 20 } ] }
  key FiscalYear,
      @Consumption.valueHelpDefinition: [{ entity: { name: 'ZI_VH_COMPANYCODE', element: 'CompanyCode' } }]
      @UI: { lineItem: [ { position: 5 } ], selectionField: [ { position: 5 } ] }
      CompanyCode,
      @Consumption.valueHelpDefinition: [{ entity: { name: 'ZI_VH_PLANT', element: 'Plant' } }]
      @UI: { lineItem: [ { position: 25 } ], selectionField: [ { position: 10 } ] }
      Plant,
      @Search.defaultSearchElement: true
      @UI: { lineItem: [ { position: 30, importance: #HIGH } ], selectionField: [ { position: 30 } ] }
      ProductionOrder,
      @UI: { lineItem: [ { position: 40 } ], selectionField: [ { position: 40 } ] }
      BatchDate,
      @Consumption.valueHelpDefinition: [{ entity: { name: 'I_ProductStdVH', element: 'Product' } }]
      @UI: { lineItem: [ { position: 50 } ], selectionField: [ { position: 50 } ] }
      GreyMaterial,
      @Consumption.valueHelpDefinition: [{ entity: { name: 'I_ProductStdVH', element: 'Product' } }]
      @UI: { lineItem: [ { position: 60 } ], selectionField: [ { position: 60 } ] }
      DyedMaterial,
      @UI: { lineItem: [ { position: 70 } ] }
      Quantity,
      @UI: { lineItem: [ { position: 80 } ] }
      BatchUnit,
      @UI: { lineItem: [ { position: 90 } ] }
      Cheeses,
      @UI: { lineItem: [ { position: 100 } ] }
      Assigned,
      @UI: { lineItem: [ { position: 110, importance: #HIGH } ], selectionField: [ { position: 70 } ] }
      Closed
}
