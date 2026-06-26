@EndUserText.label: 'Digital Signature - Projection'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
@Search.searchable: true
@ObjectModel.semanticKey: ['SignatoryId']
define root view entity ZC_DigSign
  provider contract transactional_query
  as projection on ZI_DigSign
{
  key SignatoryId,
      @Search.defaultSearchElement: true
      SignatoryName,
      Designation,
      ValidFrom,
      ValidTo,
      IsActive,
      CreatedBy,
      CreatedAt,
      LastChangedBy,
      LastChangedAt,
      LocalLastChangedAt
}
