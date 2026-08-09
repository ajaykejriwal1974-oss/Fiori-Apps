@EndUserText.label: 'Sales Organization Value Help'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@ObjectModel.resultSet.sizeCategory: #XS
@Search.searchable: true
define view entity ZI_VH_SALESORG
  as select from tvko
    left outer join tvkot on  tvkot.vkorg = tvko.vkorg
                          and tvkot.spras = $session.system_language
{
      @Search.defaultSearchElement: true
      @UI.lineItem: [ { position: 10 } ]
      @EndUserText.label: 'Sales Org'
  key tvko.vkorg  as SalesOrganization,
      @Search.defaultSearchElement: true
      @UI.lineItem: [ { position: 20 } ]
      @EndUserText.label: 'Name'
      tvkot.vtext as SalesOrganizationName
}
