@EndUserText.label: 'Transport Code Master - Projection'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
@ObjectModel.semanticKey: ['TransportCode', 'TruckNumber']
define root view entity ZC_TRANSPORT
  provider contract transactional_query
  as projection on ZI_TRANSPORT
{
  key TransportCode,
  key TruckNumber
}
