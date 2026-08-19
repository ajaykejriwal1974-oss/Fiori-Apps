@EndUserText.label: 'Label Brand Value Help'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@ObjectModel.resultSet.sizeCategory: #XS
@Search.searchable: true
// The four brands offered by the legacy ZLABEL radio group. Read distinct from
// the label master itself so no config table is needed.
define view entity ZI_VH_LABEL_BRAND
  as select distinct from zpp_label
{
      @Search.defaultSearchElement: true
      @UI.lineItem: [ { position: 10 } ]
      @EndUserText.label: 'Brand'
  key brand as Brand
}
