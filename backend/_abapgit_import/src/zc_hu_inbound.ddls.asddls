@EndUserText.label: 'Inbound Delivery HUs - Projection'
@AccessControl.authorizationCheck: #CHECK
@Metadata.allowExtensions: true
@Search.searchable: true
define root view entity ZC_HU_INBOUND
  provider contract transactional_query
  as projection on ZI_HU_INBOUND
{
  @Search.defaultSearchElement: true
  key HandlingUnit,
      InboundDelivery,
      PackagingMaterial
}
