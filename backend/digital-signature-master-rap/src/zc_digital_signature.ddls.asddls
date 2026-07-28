@EndUserText.label: 'Digital Signature Master - Projection'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
@Search.searchable: true
@ObjectModel.semanticKey: ['CompanyCode']
// Value helps reference standard released VH CDS (VERIFY the exact name per
// release); shade fields use the Shade master ZC_DD_Shade.
// SECURITY: Password (pwd) is intentionally NOT exposed via this OData
// projection - a plaintext password must not be readable/writable over the
// service. Maintain it via a secure write-only channel if ever required.
define root view entity ZC_DIGITAL_SIGNATURE
  provider contract transactional_query
  as projection on ZI_DIGITAL_SIGNATURE
{
      @Consumption.valueHelpDefinition: [{ entity: { name: 'I_CompanyCodeStdVH', element: 'CompanyCode' } }]
  key CompanyCode,
      @Search.defaultSearchElement: true
      Email,
      IpAddress,
      PfxPrefix,
      SourceFolder,
      DestinationFolder
}
