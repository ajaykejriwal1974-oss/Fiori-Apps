@EndUserText.label: 'Label Type Value Help'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@ObjectModel.resultSet.sizeCategory: #XS
@Search.searchable: true
// The label types in use (the legacy ZLABEL radio group). Read distinct from
// the master itself, so no separate config table is needed.
define view entity ZI_VH_LABEL_BRAND
  as select distinct from zpp_label
{
      @Search.defaultSearchElement: true
      @UI.lineItem: [ { position: 10 } ]
      @EndUserText.label: 'Label Type'
  key type as LabelType
}
