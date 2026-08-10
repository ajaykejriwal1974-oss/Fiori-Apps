@EndUserText.label: 'Delivery Challan'
@ObjectModel.query.implementedBy: 'ABAP:ZCL_DELIVERY_CHALLAN_QUERY'
@UI.headerInfo: { typeName: 'Carton', typeNamePlural: 'Challan Cartons',
                  title: { value: 'CartonNo' }, description: { value: 'ChallanDelivery' } }
define root custom entity ZI_DELIVERY_CHALLAN
{
      @UI.facet: [ { id: 'General', purpose: #STANDARD, type: #IDENTIFICATION_REFERENCE,
                     label: 'Carton Details', position: 10 } ]
      @EndUserText.label: 'Handling Unit'
      @UI: { lineItem: [ { position: 80, importance: #LOW } ], identification: [ { position: 80 } ] }
  key HandlingUnitNo  : venum;
      @EndUserText.label: 'Delivery / Challan'
      @Consumption.valueHelpDefinition: [ { entity: { name: 'I_OutboundDelivery', element: 'OutboundDelivery' } } ]
      @UI: { lineItem: [ { position: 10, importance: #HIGH } ],
             selectionField: [ { position: 10 } ], identification: [ { position: 10 } ] }
      ChallanDelivery : vpobjkey;
      @EndUserText.label: 'Carton No.'
      @UI: { lineItem: [ { position: 20, importance: #HIGH } ], identification: [ { position: 20 } ] }
      CartonNo        : exidv;
      @EndUserText.label: 'Sales Order'
      @Consumption.valueHelpDefinition: [ { entity: { name: 'I_SalesOrderStdVH', element: 'SalesOrder' } } ]
      @UI: { lineItem: [ { position: 70, importance: #MEDIUM } ], selectionField: [ { position: 20 } ],
             identification: [ { position: 70 } ] }
      SalesOrder      : vbeln_va;
      @EndUserText.label: 'Net Weight'
      @Semantics.quantity.unitOfMeasure: 'NetWeightUnit'
      @UI: { lineItem: [ { position: 60, importance: #HIGH } ], identification: [ { position: 60 } ] }
      NetWeight       : abap.quan(15,3);
      @EndUserText.label: 'Unit'
      NetWeightUnit   : gewei;
      @EndUserText.label: 'COP No.'
      @UI: { lineItem: [ { position: 50, importance: #MEDIUM } ], identification: [ { position: 50 } ] }
      CopNo           : zspool;
      @EndUserText.label: 'Grade'
      @Consumption.valueHelpDefinition: [ { entity: { name: 'ZI_VH_CHALLAN_GRADE', element: 'Grade' } } ]
      @UI: { lineItem: [ { position: 30, importance: #HIGH } ], selectionField: [ { position: 30 } ],
             identification: [ { position: 30 } ] }
      Grade           : zde_gcode;
      @EndUserText.label: 'Size'
      @UI: { lineItem: [ { position: 40, importance: #HIGH } ], identification: [ { position: 40 } ] }
      PackSize        : zde_size;
      @EndUserText.label: 'Created On'
      @UI: { lineItem: [ { position: 90, importance: #MEDIUM } ],
             selectionField: [ { position: 40 } ], identification: [ { position: 90 } ] }
      CreatedOn       : erdat;
      @EndUserText.label: 'Created By'
      @Consumption.valueHelpDefinition: [ { entity: { name: 'I_User', element: 'UserID' } } ]
      @UI: { lineItem: [ { position: 100, importance: #LOW } ],
             selectionField: [ { position: 50 } ], identification: [ { position: 100 } ] }
      CreatedBy       : ernam;
      @EndUserText.label: 'Created By (Name)'
      @UI: { lineItem: [ { position: 110, importance: #MEDIUM } ], identification: [ { position: 110 } ] }
      CreatedByName   : abap.char(80);
}
