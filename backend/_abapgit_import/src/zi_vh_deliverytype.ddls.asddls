@EndUserText.label: 'Delivery Type Value Help'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@ObjectModel.resultSet.sizeCategory: #XS
@Search.searchable: true
define view entity ZI_VH_DELIVERYTYPE
  as select from tvlk
    left outer join tvlkt on  tvlkt.lfart = tvlk.lfart
                          and tvlkt.spras = $session.system_language
{
      @Search.defaultSearchElement: true
      @UI.lineItem: [ { position: 10 } ]
      @EndUserText.label: 'Delivery Type'
  key tvlk.lfart  as DeliveryType,
      @Search.defaultSearchElement: true
      @UI.lineItem: [ { position: 20 } ]
      @EndUserText.label: 'Name'
      tvlkt.vtext as DeliveryTypeName
}
