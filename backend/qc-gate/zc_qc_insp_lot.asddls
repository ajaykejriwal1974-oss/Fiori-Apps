@EndUserText.label: 'QC Inspection Lot - Projection'
@AccessControl.authorizationCheck: #CHECK
@Metadata.allowExtensions: true
@Search.searchable: true
@ObjectModel.semanticKey: ['InspectionLot']
// Titled on the inspection lot rather than the batch. Batch is blank on an
// in-process lot until it resolves, and the order is blank on a greige lot not
// yet assigned to a batch; the lot number is the one field never empty.
@UI.headerInfo: { typeName: 'Inspection', typeNamePlural: 'Inspections',
                  title: { value: 'InspectionLot' }, description: { value: 'MaterialName' } }
define root view entity ZC_QC_INSP_LOT
  provider contract transactional_query
  as projection on ZI_QC_INSP_LOT
{
      @UI.facet: [ { id: 'General', purpose: #STANDARD, type: #IDENTIFICATION_REFERENCE,
                     label: 'Inspection', position: 10 },
                   { id: 'Order', purpose: #STANDARD, type: #FIELDGROUP_REFERENCE,
                     label: 'Production Order', position: 20, targetQualifier: 'OrderContext' },
                   { id: 'Batch', purpose: #STANDARD, type: #FIELDGROUP_REFERENCE,
                     label: 'Plant Batch', position: 30, targetQualifier: 'BatchContext' },
                   { id: 'Chars', purpose: #STANDARD, type: #LINEITEM_REFERENCE,
                     label: 'Characteristics', position: 40, targetElement: '_Characteristic' } ]
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

      // ---- order level: what Grey QC judges against ----------------------
      @EndUserText.label: 'Production Order'
      @Search.defaultSearchElement: true
      @UI: { lineItem: [ { position: 18, importance: #HIGH } ], selectionField: [ { position: 12 } ],
             identification: [ { position: 18 } ],
             fieldGroup: [ { qualifier: 'OrderContext', position: 10 } ] }
      ProductionOrder,
      @EndUserText.label: 'Order Source'
      @UI: { fieldGroup: [ { qualifier: 'OrderContext', position: 20 } ] }
      OrderSource,
      @EndUserText.label: 'Order on Lot'
      @UI: { fieldGroup: [ { qualifier: 'OrderContext', position: 30 } ] }
      LotOrder,
      @EndUserText.label: 'Greige Material'
      @UI: { lineItem: [ { position: 25 } ], identification: [ { position: 23 } ],
             fieldGroup: [ { qualifier: 'OrderContext', position: 40 } ] }
      GreigeMaterial,
      @EndUserText.label: 'Greige Materials on Order'
      @UI: { fieldGroup: [ { qualifier: 'OrderContext', position: 50 } ] }
      GreigeMaterialCount,
      @EndUserText.label: 'Dyed Material'
      @UI: { lineItem: [ { position: 27 } ], identification: [ { position: 24 } ],
             fieldGroup: [ { qualifier: 'OrderContext', position: 60 } ] }
      DyedMaterial,
      @EndUserText.label: 'Dyed Materials on Order'
      @UI: { fieldGroup: [ { qualifier: 'OrderContext', position: 70 } ] }
      DyedMaterialCount,
      @EndUserText.label: 'Order Quantity'
      @UI: { fieldGroup: [ { qualifier: 'OrderContext', position: 80 } ] }
      OrderQuantity,
      @EndUserText.label: 'Cheeses on Order'
      @UI: { fieldGroup: [ { qualifier: 'OrderContext', position: 90 } ] }
      OrderCheeses,
      @EndUserText.label: 'Batches on Order'
      @UI: { fieldGroup: [ { qualifier: 'OrderContext', position: 100 } ] }
      BatchCount,
      @EndUserText.label: 'Open Batches'
      @UI: { fieldGroup: [ { qualifier: 'OrderContext', position: 110 } ] }
      OpenBatchCount,
      // Counts distinct values of ZPP_BATCHN-LOTNO, which has not been a lot
      // number since 2013. Above 1 means the order's batches disagree about
      // the reference. It is an audit signal, not a count of greige lots.
      @EndUserText.label: 'Lot Refs on Order'
      @UI: { fieldGroup: [ { qualifier: 'OrderContext', position: 120 } ] }
      GreigeLotRefCount,
      @UI: { fieldGroup: [ { qualifier: 'OrderContext', position: 130 } ] }
      FirstBatchDate,
      @UI: { fieldGroup: [ { qualifier: 'OrderContext', position: 140 } ] }
      LastBatchDate,

      // ---- batch level: what Post-Dyeing and Post-Winding judge -----------
      @EndUserText.label: 'Plant Batch'
      @Search.defaultSearchElement: true
      @UI: { lineItem: [ { position: 20, importance: #HIGH } ], selectionField: [ { position: 20 } ],
             identification: [ { position: 26 } ],
             fieldGroup: [ { qualifier: 'BatchContext', position: 10 } ] }
      PlantBatch,
      @EndUserText.label: 'Batch Source'
      @UI: { fieldGroup: [ { qualifier: 'BatchContext', position: 20 } ] }
      BatchSource,
      @EndUserText.label: 'Job Card'
      @Search.defaultSearchElement: true
      @UI: { lineItem: [ { position: 19, importance: #HIGH } ], selectionField: [ { position: 18 } ],
             identification: [ { position: 21 } ],
             fieldGroup: [ { qualifier: 'BatchContext', position: 30 } ] }
      JobCard,
      // ZPP_BATCHN-BATCHNO - the plant's own batch number, one per job card,
      // e.g. 2120000023. Same value as PlantBatch by construction; it carries
      // its own name because that is the number a technician says out loud.
      // Blank until a plant batch record claims this lot.
      @EndUserText.label: 'Production Lot'
      @Search.defaultSearchElement: true
      @UI: { lineItem: [ { position: 24, importance: #HIGH } ], selectionField: [ { position: 23 } ],
             identification: [ { position: 27 } ],
             fieldGroup: [ { qualifier: 'BatchContext', position: 45 } ] }
      ProductionLot,
      // The supplier batch under inspection - QALS-CHARG on a type 01 or 08
      // lot, which is the real greige lot sitting in DRM1. Blank on in-process
      // lots, because nothing records which greige fed which batch.
      @EndUserText.label: 'Greige Lot'
      @Search.defaultSearchElement: true
      @UI: { lineItem: [ { position: 21, importance: #HIGH } ], selectionField: [ { position: 22 } ],
             identification: [ { position: 22 } ],
             fieldGroup: [ { qualifier: 'BatchContext', position: 40 } ] }
      GreigeLot,
      // ZPP_BATCHN-LOTNO. A real lot number until mid-2013, the yarn quality
      // (BRT, TEX, BCT) ever since. Shown so a technician can see what the
      // batch record says; never resolved on.
      @EndUserText.label: 'Lot Ref. (legacy)'
      @UI: { identification: [ { position: 28 } ],
             fieldGroup: [ { qualifier: 'BatchContext', position: 46 } ] }
      GreigeLotRef,
      @EndUserText.label: 'Batch Quantity'
      @UI: { lineItem: [ { position: 45 } ],
             fieldGroup: [ { qualifier: 'BatchContext', position: 50 } ] }
      BatchQuantity,
      BatchUnit,
      @EndUserText.label: 'Cheeses in Batch'
      @UI: { lineItem: [ { position: 47 } ],
             fieldGroup: [ { qualifier: 'BatchContext', position: 60 } ] }
      BatchCheeses,
      @EndUserText.label: 'Dyeing Work Centre'
      @UI: { fieldGroup: [ { qualifier: 'BatchContext', position: 70 } ] }
      DyeingWorkCentre,
      @EndUserText.label: 'Winding Work Centre'
      @UI: { fieldGroup: [ { qualifier: 'BatchContext', position: 80 } ] }
      WindingWorkCentre,
      @EndUserText.label: 'Schedule No.'
      @UI: { fieldGroup: [ { qualifier: 'BatchContext', position: 90 } ] }
      ScheduleNumber,
      @EndUserText.label: 'Batch Date'
      @UI: { fieldGroup: [ { qualifier: 'BatchContext', position: 100 } ] }
      BatchDate,
      @EndUserText.label: 'Batch Closed'
      @UI: { fieldGroup: [ { qualifier: 'BatchContext', position: 110 } ] }
      BatchClosed,
      @UI: { fieldGroup: [ { qualifier: 'BatchContext', position: 120 } ] }
      BatchAssigned,
      PlantBatchYear,
      // Open orders consuming this lot's greige material. 1 means the order
      // above was settled by elimination; more means the operator is choosing.
      @EndUserText.label: 'Open Orders on Material'
      @UI: { fieldGroup: [ { qualifier: 'OrderContext', position: 15 } ] }
      GreigeOrderCount,
      GreigeBatchCount,
      JobCardCount,

      // ---- the lot itself -------------------------------------------------
      // Batch and Supplier Lot each offer a value help over the OPEN inspection
      // lots, bound to the Plant filter through additionalBinding so the list
      // narrows to the plant the operator is working in rather than being
      // pinned to one. See ZI_VH_QC_BATCH for why "open" is the
      // results-confirmed flag and not ZPP_BATCHN-CLOSED, which is set on 7 of
      // 131,471 undeleted batches in plant 2002 and so filters nothing.
      //
      // Both lists will look empty in 2002 until the QM master data in
      // backend/qc-gate/PLANT-2002-QM-SETUP.md exists. That is the data gap
      // recorded there, not a fault in these views.
      @EndUserText.label: 'Batch'
      @Search.defaultSearchElement: true
      @Consumption.valueHelpDefinition: [ { entity: { name: 'ZI_VH_QC_BATCH', element: 'Batch' },
                                            additionalBinding: [ { localElement: 'Plant', element: 'Plant' } ] } ]
      @UI: { lineItem: [ { position: 22 } ], selectionField: [ { position: 24 } ],
             identification: [ { position: 25 } ] }
      Batch,
      @EndUserText.label: 'Supplier Lot'
      @Search.defaultSearchElement: true
      @Consumption.valueHelpDefinition: [ { entity: { name: 'ZI_VH_QC_SUPPLIER_LOT', element: 'VendorBatch' },
                                            additionalBinding: [ { localElement: 'Plant', element: 'Plant' } ] } ]
      @UI: { lineItem: [ { position: 23 } ], selectionField: [ { position: 25 } ],
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
      @EndUserText.label: 'Lot Quantity'
      @UI: { identification: [ { position: 50 } ] }
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
