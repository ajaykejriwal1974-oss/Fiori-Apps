@EndUserText.label: 'Digital Signature Master - Projection'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
@Search.searchable: true
@ObjectModel.semanticKey: ['CompanyCode']
define root view entity ZC_DigitalSignature
  provider contract transactional_query
  as projection on ZI_DigitalSignature
{
  key CompanyCode,
      @Search.defaultSearchElement: true
      Email,
      Password,
      IpAddress,
      PfxPrefix,
      SourceFolder,
      DestinationFolder
}
