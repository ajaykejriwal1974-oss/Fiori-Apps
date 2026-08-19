@EndUserText.label: 'Division Value Help'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@ObjectModel.resultSet.sizeCategory: #XS
@Search.searchable: true
define view entity ZI_VH_DIVISION
  as select from tspa
    left outer join tspat on  tspat.spart = tspa.spart
                          and tspat.spras = $session.system_language
{
      @Search.defaultSearchElement: true
      @UI.lineItem: [ { position: 10 } ]
      @EndUserText.label: 'Division'
  key tspa.spart  as Division,
      @Search.defaultSearchElement: true
      @UI.lineItem: [ { position: 20 } ]
      @EndUserText.label: 'Name'
      tspat.vtext as DivisionName
}
