@EndUserText.label: 'Checked / Packed By Master - Projection'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
@Search.searchable: true
@ObjectModel.semanticKey: ['SerialNumber', 'CheckedPackedFlag']
define root view entity ZC_CheckedBy
  provider contract transactional_query
  as projection on ZI_CheckedBy
{
  key SerialNumber,
  key CheckedPackedFlag,
      @Search.defaultSearchElement: true
      UserName
}
