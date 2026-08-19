@EndUserText.label: 'Label Master - Projection'
@AccessControl.authorizationCheck: #CHECK
@Metadata.allowExtensions: true
@Search.searchable: true
define root view entity ZC_LABEL_MASTER
  provider contract transactional_query
  as projection on ZI_LABEL_MASTER
{
      @Consumption.valueHelpDefinition: [{ entity: { name: 'ZI_VH_PLANT', element: 'Plant' } }]
      @UI: { lineItem: [ { position: 10, importance: #HIGH } ], selectionField: [ { position: 10 } ] }
  key Plant,
      @Consumption.valueHelpDefinition: [{ entity: { name: 'ZI_VH_LABEL_BRAND', element: 'Brand' } }]
      @UI: { lineItem: [ { position: 20, importance: #HIGH } ], selectionField: [ { position: 20 } ] }
  key Brand,
      @UI: { lineItem: [ { position: 30 } ] }
  key LabelNumber,
      @Consumption.valueHelpDefinition: [{ entity: { name: 'ZI_VH_COMPANYCODE', element: 'CompanyCode' } }]
      @UI: { lineItem: [ { position: 5 } ], selectionField: [ { position: 5 } ] }
      CompanyCode,
      @Search.defaultSearchElement: true
      @Consumption.valueHelpDefinition: [{ entity: { name: 'I_ProductStdVH', element: 'Product' } }]
      @UI: { lineItem: [ { position: 40 } ], selectionField: [ { position: 30 } ] }
      Material,
      @UI: { lineItem: [ { position: 50 } ], selectionField: [ { position: 40 } ] }
      Grade,
      @UI: { lineItem: [ { position: 60 } ], selectionField: [ { position: 50 } ] }
      Shade,
      @UI: { lineItem: [ { position: 70 } ] }
      PackingType,
      @Search.defaultSearchElement: true
      @UI: { lineItem: [ { position: 80, importance: #HIGH } ] }
      LabelText,
      @UI: { lineItem: [ { position: 90 } ], selectionField: [ { position: 60 } ] }
      IsActive,
      @UI: { lineItem: [ { position: 100 } ] }
      CreatedOn,
      @UI: { lineItem: [ { position: 110 } ] }
      CreatedBy,
      ChangedOn,
      ChangedBy
}
