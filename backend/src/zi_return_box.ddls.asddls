@EndUserText.label: 'Return Delivery Boxes - Unassign'
@ObjectModel.query.implementedBy: 'ABAP:ZCL_RETURN_BOX_QUERY'
// Free-text search is implemented in the query class - a custom entity gets
// none for free. Searches BoxNo / HandlingUnit / Material / MaterialText.
@Search.searchable: true
@UI.headerInfo: { typeName: 'Return Box', typeNamePlural: 'Return Boxes',
                  title: { value: 'BoxNo' }, description: { value: 'MaterialText' } }
define root custom entity ZI_RETURN_BOX
{
      @UI.facet: [ { id: 'General', purpose: #STANDARD, type: #IDENTIFICATION_REFERENCE,
                     label: 'Box Details', position: 10 } ]
      @EndUserText.label: 'Box No.'
      @Search.defaultSearchElement: true
      @UI: { lineItem: [ { position: 10, importance: #HIGH },
                         { type: #FOR_ACTION, dataAction: 'unassign', label: 'Unassign' } ],
             identification: [ { position: 10 } ] }
  key BoxNo         : abap.char(20);
      @EndUserText.label: 'Company Code'
      @Consumption.valueHelpDefinition: [ { entity: { name: 'ZI_VH_COMPANYCODE', element: 'CompanyCode' } } ]
      @UI: { lineItem: [ { position: 5, importance: #HIGH } ],
             selectionField: [ { position: 5 } ], identification: [ { position: 5 } ] }
      CompanyCode   : bukrs;
      @EndUserText.label: 'Handling Unit'
      @Search.defaultSearchElement: true
      @UI: { lineItem: [ { position: 20 } ], identification: [ { position: 20 } ] }
      HandlingUnit  : exidv;
      @EndUserText.label: 'Returns Delivery'
      @Consumption.valueHelpDefinition: [ { entity: { name: 'I_OutboundDelivery', element: 'OutboundDelivery' } } ]
      @UI: { lineItem: [ { position: 30, importance: #HIGH } ],
             selectionField: [ { position: 10 } ], identification: [ { position: 30 } ] }
      Delivery      : vbeln_vl;
      @EndUserText.label: 'Delivery Item'
      @UI: { lineItem: [ { position: 40 } ], identification: [ { position: 40 } ] }
      DeliveryItem  : posnr_vl;
      @EndUserText.label: 'Pack Object Type'
      @UI: { identification: [ { position: 50 } ] }
      PackObjType   : vpobj;
      @EndUserText.label: 'Eligible to Unassign'
      @UI: { lineItem: [ { position: 50 } ], selectionField: [ { position: 40 } ],
             identification: [ { position: 60 } ] }
      Eligible      : abap_boolean;
      @EndUserText.label: 'Material'
      @Consumption.valueHelpDefinition: [ { entity: { name: 'I_Product', element: 'Product' } } ]
      @Search.defaultSearchElement: true
      @UI: { lineItem: [ { position: 60, importance: #HIGH } ],
             selectionField: [ { position: 20 } ], identification: [ { position: 70 } ] }
      Material      : matnr;
      @EndUserText.label: 'Description'
      @Search.defaultSearchElement: true
      @UI: { lineItem: [ { position: 70, importance: #HIGH } ], identification: [ { position: 80 } ] }
      MaterialText  : maktx;
      @EndUserText.label: 'Plant'
      @Consumption.valueHelpDefinition: [ { entity: { name: 'ZI_VH_PLANT', element: 'Plant' } } ]
      @UI: { lineItem: [ { position: 80 } ], selectionField: [ { position: 30 } ],
             identification: [ { position: 90 } ] }
      Plant         : werks_d;
      @EndUserText.label: 'Sales Order'
      @UI: { lineItem: [ { position: 90 } ], identification: [ { position: 100 } ] }
      SalesOrder    : vbeln_va;
      @EndUserText.label: 'Fiscal Year'
      @UI: { identification: [ { position: 110 } ] }
      FiscalYear    : gjahr;
      @EndUserText.label: 'Net Weight'
      @UI: { lineItem: [ { position: 100 } ], identification: [ { position: 120 } ] }
      @Semantics.quantity.unitOfMeasure: 'WeightUnit'
      NetWeight     : abap.quan(13,3);
      @EndUserText.label: 'Unit'
      WeightUnit    : meins;
}
