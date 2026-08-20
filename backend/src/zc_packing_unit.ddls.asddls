@EndUserText.label: 'Packing Units (existing HU) - Projection'
@AccessControl.authorizationCheck: #CHECK
@Metadata.allowExtensions: true
@Search.searchable: true
@ObjectModel.semanticKey: ['HandlingUnit']
@UI.headerInfo: { typeName: 'Packing Unit', typeNamePlural: 'Packing Units',
                  title: { value: 'HandlingUnit' }, description: { value: 'PackagingMaterial' } }
define root view entity ZC_PACKING_UNIT
  provider contract transactional_query
  as projection on ZI_PACKING_UNIT
{
      @UI.facet: [ { id: 'General', purpose: #STANDARD, type: #IDENTIFICATION_REFERENCE,
                     label: 'Packing Unit', position: 10 } ]
      @EndUserText.label: 'Handling Unit'
      @Search.defaultSearchElement: true
      @UI: { lineItem: [ { position: 10, importance: #HIGH } ],
             selectionField: [ { position: 10 } ], identification: [ { position: 10 } ] }
  key HandlingUnit,
      @EndUserText.label: 'Company Code'
      @Consumption.valueHelpDefinition: [ { entity: { name: 'ZI_VH_COMPANYCODE', element: 'CompanyCode' } } ]
      @UI: { lineItem: [ { position: 5, importance: #HIGH } ],
             selectionField: [ { position: 5 } ], identification: [ { position: 5 } ] }
      CompanyCode,
      @EndUserText.label: 'Plant'
      @Consumption.valueHelpDefinition: [ { entity: { name: 'ZI_VH_PLANT', element: 'Plant' } } ]
      @UI: { lineItem: [ { position: 6, importance: #HIGH } ],
             selectionField: [ { position: 6 } ], identification: [ { position: 6 } ] }
      Plant,
      @EndUserText.label: 'Reference Doc'
      @Search.defaultSearchElement: true
      @UI: { lineItem: [ { position: 20 } ], selectionField: [ { position: 20 } ],
             identification: [ { position: 20 } ] }
      Reference,
      @EndUserText.label: 'Packing Material'
      @Consumption.valueHelpDefinition: [ { entity: { name: 'I_Product', element: 'Product' } } ]
      @UI: { lineItem: [ { position: 30, importance: #HIGH } ], selectionField: [ { position: 30 } ],
             identification: [ { position: 30 } ] }
      PackagingMaterial,
      @EndUserText.label: 'Net Weight'
      @UI: { lineItem: [ { position: 40, importance: #HIGH } ], identification: [ { position: 40 } ] }
      NetWeight,
      @EndUserText.label: 'Gross Weight'
      @UI: { lineItem: [ { position: 50 } ], identification: [ { position: 50 } ] }
      GrossWeight,
      @EndUserText.label: 'Unit'
      @UI: { identification: [ { position: 60 } ] }
      WeightUnit,
      @EndUserText.label: 'Packing Group'
      @UI: { lineItem: [ { position: 60 } ], selectionField: [ { position: 40 } ],
             identification: [ { position: 70 } ] }
      PackingGroup
}
