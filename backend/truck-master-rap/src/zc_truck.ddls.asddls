@EndUserText.label: 'Truck Master - Projection'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
@Search.searchable: true
@ObjectModel.semanticKey: ['TruckNumber']
define root view entity ZC_Truck
  provider contract transactional_query
  as projection on ZI_Truck
{
  key TruckNumber,
      @Search.defaultSearchElement: true
      CarrierName
}
