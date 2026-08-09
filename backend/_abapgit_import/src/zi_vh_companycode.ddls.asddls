@EndUserText.label: 'Company Code Value Help'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@ObjectModel.resultSet.sizeCategory: #XS
@Search.searchable: true
define view entity ZI_VH_COMPANYCODE
  as select from t001
{
      @Search.defaultSearchElement: true
      @UI.lineItem: [ { position: 10 } ]
      @EndUserText.label: 'Company Code'
  key bukrs as CompanyCode,
      @Search.defaultSearchElement: true
      @UI.lineItem: [ { position: 20 } ]
      @EndUserText.label: 'Name'
      butxt as CompanyCodeName
}
