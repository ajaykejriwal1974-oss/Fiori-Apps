@EndUserText.label: 'Print Label Master - Projection'
@AccessControl.authorizationCheck: #CHECK
@Metadata.allowExtensions: true
@Search.searchable: true
@UI.headerInfo: { typeName: 'Label Printer', typeNamePlural: 'Label Printers',
                  title: { value: 'LabelText' }, description: { value: 'IPAddress' } }
define root view entity ZC_LABEL_MASTER
  provider contract transactional_query
  as projection on ZI_LABEL_MASTER
{
      @UI.facet: [ { id: 'General', purpose: #STANDARD, type: #IDENTIFICATION_REFERENCE,
                     label: 'Label Printer', position: 10 } ]
      @EndUserText.label: 'Plant'
      @Consumption.valueHelpDefinition: [{ entity: { name: 'ZI_VH_PLANT', element: 'Plant' } }]
      @UI: { lineItem: [ { position: 10, importance: #HIGH } ],
             selectionField: [ { position: 10 } ], identification: [ { position: 10 } ] }
  key Plant,
      @EndUserText.label: 'Label Type'
      @Consumption.valueHelpDefinition: [{ entity: { name: 'ZI_VH_LABEL_BRAND', element: 'LabelType' } }]
      @UI: { lineItem: [ { position: 20, importance: #HIGH } ],
             selectionField: [ { position: 20 } ], identification: [ { position: 20 } ] }
  key LabelType,
      @EndUserText.label: 'Printer IP Address'
      @Search.defaultSearchElement: true
      @UI: { lineItem: [ { position: 30, importance: #HIGH } ],
             selectionField: [ { position: 30 } ], identification: [ { position: 30 } ] }
  key IPAddress,
      @EndUserText.label: 'Description'
      @Search.defaultSearchElement: true
      @UI: { lineItem: [ { position: 40, importance: #HIGH } ], identification: [ { position: 40 } ] }
      LabelText,
      @EndUserText.label: 'Default'
      @UI: { lineItem: [ { position: 50 } ], selectionField: [ { position: 40 } ],
             identification: [ { position: 50 } ] }
      IsDefault
}
