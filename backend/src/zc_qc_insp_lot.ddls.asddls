@EndUserText.label: 'QC Inspection Lot - Projection'
@AccessControl.authorizationCheck: #CHECK
@Metadata.allowExtensions: true
@Search.searchable: true
@ObjectModel.semanticKey: ['InspectionLot']
@UI.headerInfo: { typeName: 'Inspection', typeNamePlural: 'Inspections',
                  title: { value: 'Batch' }, description: { value: 'MaterialName' } }
define root view entity ZC_QC_INSP_LOT
  provider contract transactional_query
  as projection on ZI_QC_INSP_LOT
{
      @UI.facet: [ { id: 'General', purpose: #STANDARD, type: #IDENTIFICATION_REFERENCE,
                     label: 'Inspection', position: 10 },
                   { id: 'Chars', purpose: #STANDARD, type: #LINEITEM_REFERENCE,
                     label: 'Characteristics', position: 20, targetElement: '_Characteristic' } ]
      @EndUserText.label: 'Inspection Lot'
      @Search.defaultSearchElement: true
      @UI: { lineItem: [ { position: 10, importance: #HIGH } ], identification: [ { position: 10 } ] }
  key InspectionLot,
      @EndUserText.label: 'Company Code'
      @Consumption.valueHelpDefinition: [ { entity: { name: 'ZI_VH_COMPANYCODE', element: 'CompanyCode' } } ]
      @UI: { selectionField: [ { position: 5 } ], identification: [ { position: 5 } ] }
      CompanyCode,
      @EndUserText.label: 'Plant'
      @Consumption.valueHelpDefinition: [ { entity: { name: 'ZI_VH_PLANT', element: 'Plant' } } ]
      @UI: { lineItem: [ { position: 15 } ], selectionField: [ { position: 10 } ],
             identification: [ { position: 15 } ] }
      Plant,
      @EndUserText.label: 'Inspection Type'
      @UI: { selectionField: [ { position: 15 } ], identification: [ { position: 20 } ] }
      InspectionType,
      @EndUserText.label: 'Batch'
      @Search.defaultSearchElement: true
      @UI: { lineItem: [ { position: 20, importance: #HIGH } ], selectionField: [ { position: 20 } ],
             identification: [ { position: 25 } ] }
      Batch,
      @EndUserText.label: 'Supplier Lot'
      @Search.defaultSearchElement: true
      @UI: { lineItem: [ { position: 25 } ], selectionField: [ { position: 25 } ],
             identification: [ { position: 30 } ] }
      VendorBatch,
      @EndUserText.label: 'Material'
      @Search.defaultSearchElement: true
      @UI: { lineItem: [ { position: 30 } ], selectionField: [ { position: 30 } ],
             identification: [ { position: 35 } ] }
      Material,
      @EndUserText.label: 'Description'
      @Search.defaultSearchElement: true
      @UI: { lineItem: [ { position: 35, importance: #HIGH } ], identification: [ { position: 40 } ] }
      MaterialName,
      @EndUserText.label: 'Production Order'
      @UI: { lineItem: [ { position: 40 } ], selectionField: [ { position: 35 } ],
             identification: [ { position: 45 } ] }
      ProductionOrder,
      @EndUserText.label: 'Lot Quantity'
      @UI: { lineItem: [ { position: 45 } ], identification: [ { position: 50 } ] }
      LotQuantity,
      LotUnit,
      @EndUserText.label: 'Sample Size'
      @UI: { identification: [ { position: 55 } ] }
      SampleSize,
      SampleUnit,
      @EndUserText.label: 'Created On'
      @UI: { lineItem: [ { position: 50 } ], selectionField: [ { position: 40 } ],
             identification: [ { position: 60 } ] }
      CreatedOn,
      @EndUserText.label: 'Results Confirmed'
      @UI: { lineItem: [ { position: 55 } ], identification: [ { position: 65 } ] }
      ResultsConfirmed,
      @EndUserText.label: 'UD Made'
      @UI: { lineItem: [ { position: 60 } ], identification: [ { position: 70 } ] }
      UsageDecisionMade,
      @EndUserText.label: 'Open'
      @UI: { selectionField: [ { position: 45 } ] }
      IsOpen,
      StartDate,
      EndDate,
      LotOrigin,
      LotText,
      _Characteristic : redirected to ZC_QC_INSP_CHAR
}
