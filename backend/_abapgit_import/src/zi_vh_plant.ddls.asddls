@EndUserText.label: 'Plant Value Help'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@ObjectModel.resultSet.sizeCategory: #XS
@Search.searchable: true
define view entity ZI_VH_PLANT
  as select from t001w
{
      @Search.defaultSearchElement: true
      @UI.lineItem: [ { position: 10 } ]
      @EndUserText.label: 'Plant'
  key werks as Plant,
      @Search.defaultSearchElement: true
      @UI.lineItem: [ { position: 20 } ]
      @EndUserText.label: 'Name'
      name1 as PlantName
}
