@EndUserText.label: 'Distribution Channel Value Help'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@ObjectModel.resultSet.sizeCategory: #XS
@Search.searchable: true
define view entity ZI_VH_DISTCHANNEL
  as select from tvtw
    left outer join tvtwt on  tvtwt.vtweg = tvtw.vtweg
                          and tvtwt.spras = $session.system_language
{
      @Search.defaultSearchElement: true
      @UI.lineItem: [ { position: 10 } ]
      @EndUserText.label: 'Distribution Channel'
  key tvtw.vtweg  as DistributionChannel,
      @Search.defaultSearchElement: true
      @UI.lineItem: [ { position: 20 } ]
      @EndUserText.label: 'Name'
      tvtwt.vtext as DistributionChannelName
}
