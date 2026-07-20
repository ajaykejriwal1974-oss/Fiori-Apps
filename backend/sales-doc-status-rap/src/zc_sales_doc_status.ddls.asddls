@EndUserText.label: 'Sales Document Status - Projection'
@AccessControl.authorizationCheck: #CHECK
@Metadata.allowExtensions: true
@Search.searchable: true
@ObjectModel.semanticKey: ['SalesDocument']

@UI.headerInfo: {
  typeName: 'Sales Document',
  typeNamePlural: 'Sales Documents',
  title: { type: #STANDARD, value: 'SalesDocument' },
  description: { type: #STANDARD, value: 'OverallProcessingStatus' }
}
define root view entity ZC_SalesDocStatus
  provider contract transactional_query
  as projection on ZI_SalesDocStatus
{
      @Search.defaultSearchElement: true
      @UI: { lineItem:       [ { position: 10 } ],
             identification: [ { position: 10 } ],
             selectionField: [ { position: 10 } ] }
  key SalesDocument,

      @UI: { lineItem:       [ { position: 20 } ],
             identification: [ { position: 20 } ] }
      DocumentCategory,

      @UI: { lineItem:       [ { position: 30 } ],
             identification: [ { position: 30 } ],
             selectionField: [ { position: 20 } ] }
      SalesDocumentType,

      @UI: { lineItem:       [ { position: 40 } ],
             identification: [ { position: 40 } ],
             selectionField: [ { position: 30 } ] }
      SalesOrganization,

      @UI: { lineItem:       [ { position: 50 } ],
             identification: [ { position: 50 } ],
             selectionField: [ { position: 40 } ] }
      SoldToParty,

      @UI: { lineItem:       [ { position: 60 } ],
             identification: [ { position: 60 } ] }
      NetValue,

      @UI: { lineItem:       [ { position: 70 } ],
             identification: [ { position: 70 } ] }
      Currency,

      @UI: { lineItem:       [ { position: 80 } ],
             identification: [ { position: 80 } ],
             selectionField: [ { position: 50 } ] }
      OverallProcessingStatus,

      @UI: { lineItem:       [ { position: 90 } ],
             identification: [ { position: 90 } ] }
      CreatedOnDate
}
