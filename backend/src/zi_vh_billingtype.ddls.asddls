@EndUserText.label: 'Billing Type Value Help'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@ObjectModel.resultSet.sizeCategory: #XS
@Search.searchable: true
define view entity ZI_VH_BILLINGTYPE
  as select from tvfk
    left outer join tvfkt on  tvfkt.fkart = tvfk.fkart
                          and tvfkt.spras = $session.system_language
{
      @Search.defaultSearchElement: true
      @UI.lineItem: [ { position: 10 } ]
      @EndUserText.label: 'Billing Type'
  key tvfk.fkart  as BillingType,
      @Search.defaultSearchElement: true
      @UI.lineItem: [ { position: 20 } ]
      @EndUserText.label: 'Name'
      tvfkt.vtext as BillingTypeName
}
