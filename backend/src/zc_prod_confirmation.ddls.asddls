@EndUserText.label: 'Production Confirmation - Projection'
@AccessControl.authorizationCheck: #CHECK
@Metadata.allowExtensions: true
@Search.searchable: true
define root view entity ZC_PROD_CONFIRMATION
  provider contract transactional_query
  as projection on ZI_PROD_CONFIRMATION
{
      @Search.defaultSearchElement: true
      @UI: { lineItem: [ { position: 10, importance: #HIGH } ] }
  key ConfirmationNumber,
      @UI: { lineItem: [ { position: 20 } ] }
  key ConfirmationCounter,
      @Consumption.valueHelpDefinition: [{ entity: { name: 'ZI_VH_COMPANYCODE', element: 'CompanyCode' } }]
      @UI: { lineItem: [ { position: 5 } ], selectionField: [ { position: 5 } ] }
      CompanyCode,
      @Consumption.valueHelpDefinition: [{ entity: { name: 'ZI_VH_PLANT', element: 'Plant' } }]
      @UI: { lineItem: [ { position: 25 } ], selectionField: [ { position: 10 } ] }
      Plant,
      @Search.defaultSearchElement: true
      @UI: { lineItem: [ { position: 30, importance: #HIGH } ], selectionField: [ { position: 20 } ] }
      OrderNumber,
      @UI: { lineItem: [ { position: 40 } ], selectionField: [ { position: 30 } ] }
      OperationNumber,
      @Consumption.valueHelpDefinition: [{ entity: { name: 'I_ProductStdVH', element: 'Product' } }]
      @UI: { lineItem: [ { position: 50 } ], selectionField: [ { position: 40 } ] }
      Material,
      @UI: { lineItem: [ { position: 60, importance: #HIGH } ], selectionField: [ { position: 50 } ] }
      PostingDate,
      @UI: { lineItem: [ { position: 70 } ] }
      YieldQuantity,
      @UI: { lineItem: [ { position: 80 } ] }
      ScrapQuantity,
      @UI: { lineItem: [ { position: 90 } ] }
      ConfirmationUnit,
      @UI: { lineItem: [ { position: 100 } ] }
      ActualWork,
      @UI: { lineItem: [ { position: 110 } ] }
      ActualWorkUnit,
      @UI: { lineItem: [ { position: 120 } ] }
      IsCancelled,
      ReversalCounter,
      @Consumption.valueHelpDefinition: [{ entity: { name: 'ZI_VH_USER', element: 'UserID' } }]
      @UI: { lineItem: [ { position: 130 } ], selectionField: [ { position: 60 } ] }
      CreatedBy,
      @UI: { lineItem: [ { position: 140 } ] }
      CreatedOn,
      ExecutionStartDate
}
