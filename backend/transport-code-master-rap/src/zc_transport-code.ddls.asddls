@EndUserText.label: 'Transport Code - Projection'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
@Search.searchable: true
@ObjectModel.semanticKey: ['TransportCode']
define root view entity ZC_TransportCode
  provider contract transactional_query
  as projection on ZI_TransportCode
{
  key TransportCode,
      @Search.defaultSearchElement: true
      TransportName,
      TransportMode,
      IsActive,
      CreatedBy,
      CreatedAt,
      LastChangedBy,
      LastChangedAt,
      LocalLastChangedAt
}
