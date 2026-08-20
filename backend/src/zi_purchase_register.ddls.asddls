@EndUserText.label: 'Purchase Register - GST (ZPUREG)'
@ObjectModel.query.implementedBy: 'ABAP:ZCL_PURCHASE_REGISTER_QUERY'
// Free-text search is implemented in the query class - a custom entity gets
// none for free. Searches MMInvoiceNo / VendorInvoiceNo / Supplier /
// SupplierName / SupplierGSTIN.
@Search.searchable: true
@UI.headerInfo: { typeName: 'Purchase Invoice', typeNamePlural: 'Purchase Register',
                  title: { value: 'MMInvoiceNo' }, description: { value: 'SupplierName' } }
define custom entity ZI_PURCHASE_REGISTER
{
      @UI.facet: [ { id: 'General', purpose: #STANDARD, type: #IDENTIFICATION_REFERENCE,
                     label: 'Invoice', position: 10 } ]
      @EndUserText.label: 'Company Code'
      @Consumption.valueHelpDefinition: [ { entity: { name: 'ZI_VH_COMPANYCODE', element: 'CompanyCode' } } ]
      @UI: { lineItem: [ { position: 10, importance: #HIGH } ],
             selectionField: [ { position: 10 } ], identification: [ { position: 10 } ] }
  key CompanyCode     : bukrs;
      @Search.defaultSearchElement: true
      @EndUserText.label: 'Invoice No.'
      @UI: { lineItem: [ { position: 20, importance: #HIGH } ], identification: [ { position: 20 } ] }
  key MMInvoiceNo     : re_belnr;
      @EndUserText.label: 'Fiscal Year'
      @UI: { lineItem: [ { position: 30 } ], selectionField: [ { position: 20 } ],
             identification: [ { position: 30 } ] }
  key FiscalYear      : gjahr;
      @EndUserText.label: 'Posting Date'
      @UI: { lineItem: [ { position: 40, importance: #HIGH } ], selectionField: [ { position: 30 } ],
             identification: [ { position: 40 } ] }
      PostingDate     : budat;
      @EndUserText.label: 'Document Date'
      @UI: { identification: [ { position: 50 } ] }
      DocumentDate    : bldat;
      @Search.defaultSearchElement: true
      @EndUserText.label: 'Vendor Invoice No.'
      @UI: { lineItem: [ { position: 50 } ], identification: [ { position: 60 } ] }
      VendorInvoiceNo : xblnr1;
      @Search.defaultSearchElement: true
      @EndUserText.label: 'Supplier'
      @Consumption.valueHelpDefinition: [ { entity: { name: 'I_Supplier', element: 'Supplier' } } ]
      @UI: { lineItem: [ { position: 60 } ], selectionField: [ { position: 40 } ],
             identification: [ { position: 70 } ] }
      Supplier        : lifnr;
      @Search.defaultSearchElement: true
      @EndUserText.label: 'Supplier Name'
      @UI: { lineItem: [ { position: 70, importance: #HIGH } ], identification: [ { position: 80 } ] }
      SupplierName    : name1_gp;
      @Search.defaultSearchElement: true
      @EndUserText.label: 'Supplier GSTIN'
      @UI: { lineItem: [ { position: 80 } ], identification: [ { position: 90 } ] }
      SupplierGSTIN   : stcd3;
      @EndUserText.label: 'Currency'
      @UI: { identification: [ { position: 100 } ] }
      Currency        : waers;
      @EndUserText.label: 'Gross Amount'
      @UI: { lineItem: [ { position: 90, importance: #HIGH } ], identification: [ { position: 110 } ] }
      @Semantics.amount.currencyCode: 'Currency'
      GrossAmount     : abap.curr(16,2);
      @EndUserText.label: 'Taxable Value'
      @UI: { lineItem: [ { position: 100, importance: #HIGH } ], identification: [ { position: 120 } ] }
      @Semantics.amount.currencyCode: 'Currency'
      BaseAmount      : abap.curr(16,2);
      @EndUserText.label: 'CGST'
      @UI: { lineItem: [ { position: 110 } ], identification: [ { position: 130 } ] }
      @Semantics.amount.currencyCode: 'Currency'
      CGSTAmount      : abap.curr(16,2);
      @EndUserText.label: 'SGST'
      @UI: { lineItem: [ { position: 120 } ], identification: [ { position: 140 } ] }
      @Semantics.amount.currencyCode: 'Currency'
      SGSTAmount      : abap.curr(16,2);
      @EndUserText.label: 'IGST'
      @UI: { lineItem: [ { position: 130 } ], identification: [ { position: 150 } ] }
      @Semantics.amount.currencyCode: 'Currency'
      IGSTAmount      : abap.curr(16,2);
      @EndUserText.label: 'Total Tax'
      @UI: { lineItem: [ { position: 140, importance: #HIGH } ], identification: [ { position: 160 } ] }
      @Semantics.amount.currencyCode: 'Currency'
      TotalTax        : abap.curr(16,2);
      @EndUserText.label: 'RCM CGST'
      @UI: { identification: [ { position: 170 } ] }
      @Semantics.amount.currencyCode: 'Currency'
      RCMCGSTAmount   : abap.curr(16,2);
      @EndUserText.label: 'RCM SGST'
      @UI: { identification: [ { position: 180 } ] }
      @Semantics.amount.currencyCode: 'Currency'
      RCMSGSTAmount   : abap.curr(16,2);
      @EndUserText.label: 'RCM IGST'
      @UI: { identification: [ { position: 190 } ] }
      @Semantics.amount.currencyCode: 'Currency'
      RCMIGSTAmount   : abap.curr(16,2);
      @EndUserText.label: 'RCM Total Tax'
      @UI: { identification: [ { position: 200 } ] }
      @Semantics.amount.currencyCode: 'Currency'
      RCMTotalTax     : abap.curr(16,2);
}
