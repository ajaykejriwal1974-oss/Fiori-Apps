@EndUserText.label: 'Grade Value Help (Challan)'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@ObjectModel.resultSet.sizeCategory: #XS
@Search.searchable: true
define view entity ZI_VH_CHALLAN_GRADE
  as select from zpp_pack
{
      @Search.defaultSearchElement: true
      @UI.lineItem: [ { position: 10 } ]
      @EndUserText.label: 'Grade'
  key grade as Grade
}
group by grade
