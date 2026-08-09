@EndUserText.label: 'Digital Signature Master - Projection'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
@Search.searchable: true
@ObjectModel.semanticKey: ['CompanyCode']
define root view entity ZC_DIGITAL_SIGNATURE
  provider contract transactional_query
  as projection on ZI_DIGITAL_SIGNATURE
{
      @Search.defaultSearchElement: true
      @Consumption.valueHelpDefinition: [{ entity: { name: 'ZI_VH_COMPANYCODE', element: 'CompanyCode' } }]
      @UI: { lineItem: [ { position: 10, importance: #HIGH } ], selectionField: [ { position: 10 } ] }
  key CompanyCode,
      @UI: { lineItem: [ { position: 20 } ] }
      Email,
      @UI: { lineItem: [ { position: 30 } ] }
      IpAddress,
      @UI: { lineItem: [ { position: 40 } ] }
      PfxPrefix,
      @UI: { lineItem: [ { position: 50 } ] }
      SourceFolder,
      @UI: { lineItem: [ { position: 60 } ] }
      DestinationFolder
}
