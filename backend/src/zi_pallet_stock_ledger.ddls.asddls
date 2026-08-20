@EndUserText.label: 'Pallet Stock at Customer (ZPEL)'
@ObjectModel.query.implementedBy: 'ABAP:ZCL_PALLET_STOCK_QUERY'
// Free-text search is handled in the query class - a custom entity gets no
// search for free. ZCL_PALLET_STOCK_QUERY reads io_request->get_search_expression()
// and filters Customer / Material / the two description fields.
@Search.searchable: true
@UI.headerInfo: { typeName: 'Pallet Stock', typeNamePlural: 'Pallet Stock',
                  title: { value: 'Material' }, description: { value: 'MaterialDescription' } }
define custom entity ZI_PALLET_STOCK_LEDGER
{
      @UI.facet: [ { id: 'General', purpose: #STANDARD, type: #IDENTIFICATION_REFERENCE,
                     label: 'Stock', position: 10 } ]
      @EndUserText.label: 'Company Code'
      @Consumption.valueHelpDefinition: [ { entity: { name: 'ZI_VH_COMPANYCODE', element: 'CompanyCode' } } ]
      @UI: { lineItem: [ { position: 5, importance: #HIGH } ], selectionField: [ { position: 5 } ], identification: [ { position: 5 } ] }
      CompanyCode         : bukrs;
      @EndUserText.label: 'Plant'
      @Consumption.valueHelpDefinition: [ { entity: { name: 'ZI_VH_PLANT', element: 'Plant' } } ]
      @UI: { lineItem: [ { position: 10, importance: #HIGH } ], selectionField: [ { position: 10 } ], identification: [ { position: 10 } ] }
  key Plant               : werks_d;
      @EndUserText.label: 'Customer'
      @Consumption.valueHelpDefinition: [ { entity: { name: 'I_Customer', element: 'Customer' } } ]
      @Search.defaultSearchElement: true
      @UI: { lineItem: [ { position: 20, importance: #HIGH } ], selectionField: [ { position: 20 } ], identification: [ { position: 20 } ] }
  key Customer            : kunnr;
      @EndUserText.label: 'Material'
      @Consumption.valueHelpDefinition: [ { entity: { name: 'I_Product', element: 'Product' } } ]
      @Search.defaultSearchElement: true
      @UI: { lineItem: [ { position: 30, importance: #HIGH } ], selectionField: [ { position: 30 } ], identification: [ { position: 30 } ] }
  key Material            : matnr;
      @EndUserText.label: 'Base Unit'
      @UI: { identification: [ { position: 40 } ] }
      BaseUnit            : meins;
      @EndUserText.label: 'Customer Name'
      @Search.defaultSearchElement: true
      @UI: { lineItem: [ { position: 40 } ], identification: [ { position: 50 } ] }
      CustomerName        : name1_gp;
      @EndUserText.label: 'Description'
      @Search.defaultSearchElement: true
      @UI: { lineItem: [ { position: 50 } ], identification: [ { position: 60 } ] }
      MaterialDescription : maktx;
      @EndUserText.label: 'Unrestricted'
      @UI: { lineItem: [ { position: 60, importance: #HIGH } ], identification: [ { position: 70 } ] }
      @Semantics.quantity.unitOfMeasure: 'BaseUnit'
      UnrestrictedStock   : abap.quan(15,3);
      @EndUserText.label: 'Quality Insp.'
      @UI: { lineItem: [ { position: 70 } ], identification: [ { position: 80 } ] }
      @Semantics.quantity.unitOfMeasure: 'BaseUnit'
      QualityInspStock    : abap.quan(15,3);
      @EndUserText.label: 'Blocked'
      @UI: { lineItem: [ { position: 80 } ], identification: [ { position: 90 } ] }
      @Semantics.quantity.unitOfMeasure: 'BaseUnit'
      RestrictedStock     : abap.quan(15,3);
      @EndUserText.label: 'Total at Customer'
      @UI: { lineItem: [ { position: 90, importance: #HIGH } ], identification: [ { position: 100 } ] }
      @Semantics.quantity.unitOfMeasure: 'BaseUnit'
      StockAtCustomer     : abap.quan(15,3);
}
