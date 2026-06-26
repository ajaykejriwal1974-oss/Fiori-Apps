@EndUserText.label: 'Transport Code Master - Projection'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
@Search.searchable: true
@ObjectModel.semanticKey: ['TransportCode', 'TruckNumber']
define root view entity ZC_Transport
  provider contract transactional_query
  as projection on ZI_Transport
{
  key TransportCode,
  key TruckNumber,
      @Search.defaultSearchElement: true
      Description
}
