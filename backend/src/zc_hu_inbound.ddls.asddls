@EndUserText.label: 'Inbound Delivery HUs - Projection'
@AccessControl.authorizationCheck: #CHECK
@Metadata.allowExtensions: true
@Search.searchable: true
define root view entity ZC_HU_INBOUND
  provider contract transactional_query
  as projection on ZI_HU_INBOUND
{
      @Search.defaultSearchElement: true
      @UI: { lineItem: [ { position: 10, importance: #HIGH } ], selectionField: [ { position: 10 } ] }
  key HandlingUnit,
      @UI: { lineItem: [ { position: 20 } ], selectionField: [ { position: 20 } ] }
      InboundDelivery,
      @Consumption.valueHelpDefinition: [{ entity: { name: 'I_Product', element: 'Product' } }]
      @UI: { lineItem: [ { position: 30, importance: #HIGH } ], selectionField: [ { position: 30 } ] }
      PackagingMaterial
}
