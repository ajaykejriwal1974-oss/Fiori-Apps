@EndUserText.label: 'Digital Signature Master - Projection'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
@Search.searchable: true
@ObjectModel.semanticKey: ['CompanyCode']
// Value helps reference standard released VH CDS (VERIFY the exact name per
// release); shade fields use the Shade master ZC_DD_Shade.
define root view entity ZC_DigitalSignature
  provider contract transactional_query
  as projection on ZI_DigitalSignature
{
      @Consumption.valueHelpDefinition: [{ entity: { name: 'I_CompanyCodeStdVH', element: 'CompanyCode' } }]
  key CompanyCode,
      @Search.defaultSearchElement: true
      Email,
      Password,
      IpAddress,
      PfxPrefix,
      SourceFolder,
      DestinationFolder
}
