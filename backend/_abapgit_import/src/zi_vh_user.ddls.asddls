@EndUserText.label: 'User Value Help'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@ObjectModel.resultSet.sizeCategory: #S
@Search.searchable: true
define view entity ZI_VH_USER
  as select from usr21
{
      @Search.defaultSearchElement: true
      @UI.lineItem: [{ position: 10 }]
  key bname as UserID
}
