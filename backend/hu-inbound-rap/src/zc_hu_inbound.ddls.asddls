@EndUserText.label: 'Inbound Delivery HUs - Projection'
@AccessControl.authorizationCheck: #CHECK
@Metadata.allowExtensions: true
@Search.searchable: true
define root view entity ZC_InboundHu
  provider contract transactional_query
  as projection on ZI_InboundHu
{
  key HandlingUnit,
      InboundDelivery,
      PackagingMaterial
}
