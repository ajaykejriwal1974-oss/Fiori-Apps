@EndUserText.label: 'Dyeing Recipe Master - Projection'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
@Search.searchable: true
@ObjectModel.semanticKey: ['Plant', 'GreyCode', 'DyeCode', 'ShadeCode', 'ItemNumber']
define root view entity ZC_Recipe
  provider contract transactional_query
  as projection on ZI_Recipe
{
      @Consumption.valueHelpDefinition: [{ entity: { name: 'ZI_VH_PLANT', element: 'Plant' } }]
      @UI: { lineItem: [ { position: 10, importance: #HIGH } ], selectionField: [ { position: 10 } ] }
  key Plant,
      @Consumption.valueHelpDefinition: [{ entity: { name: 'I_Product', element: 'Product' } }]
      @UI: { lineItem: [ { position: 20, importance: #HIGH } ], selectionField: [ { position: 20 } ] }
  key GreyCode,
      @Consumption.valueHelpDefinition: [{ entity: { name: 'I_Product', element: 'Product' } }]
      @UI: { lineItem: [ { position: 30, importance: #HIGH } ], selectionField: [ { position: 30 } ] }
  key DyeCode,
      @Consumption.valueHelpDefinition: [{ entity: { name: 'ZC_DD_Shade', element: 'ShadeCode' } }]
      @UI: { lineItem: [ { position: 40 } ], selectionField: [ { position: 40 } ] }
  key ShadeCode,
      @UI: { lineItem: [ { position: 50 } ] }
  key ItemNumber,
      @Search.defaultSearchElement: true
      @UI: { lineItem: [ { position: 60 } ] }
      GreyItemDesc,
      @UI: { lineItem: [ { position: 70 } ] }
      DyeItemDesc,
      @Consumption.valueHelpDefinition: [{ entity: { name: 'I_Product', element: 'Product' } }]
      @UI: { lineItem: [ { position: 80 } ], selectionField: [ { position: 50 } ] }
      Component,
      @UI: { lineItem: [ { position: 90 } ] }
      ComponentDesc,
      @UI: { lineItem: [ { position: 100 } ] }
      ComponentType,
      @UI: { lineItem: [ { position: 110 } ] }
      Ratio,
      @Consumption.valueHelpDefinition: [{ entity: { name: 'I_UnitOfMeasure', element: 'UnitOfMeasure' } }]
      @UI: { lineItem: [ { position: 120 } ] }
      SalesUnit,
      @UI: { lineItem: [ { position: 130 } ] }
      Remarks,
      CreatedBy,
      CreatedOnDate,
      CreatedAtTime,
      LastChangedBy,
      LastChangedDate,
      LastChangedTime
}
