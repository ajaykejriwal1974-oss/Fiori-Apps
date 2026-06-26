@EndUserText.label: 'Dyeing Recipe Master - Projection'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
@Search.searchable: true
@ObjectModel.semanticKey: ['Plant', 'GreyCode', 'DyeCode', 'ShadeCode', 'ItemNumber']
define root view entity ZC_Recipe
  provider contract transactional_query
  as projection on ZI_Recipe
{
  key Plant,
  key GreyCode,
  key DyeCode,
  key ShadeCode,
  key ItemNumber,
      @Search.defaultSearchElement: true
      GreyItemDesc,
      DyeItemDesc,
      Component,
      ComponentDesc,
      ComponentType,
      Ratio,
      SalesUnit,
      Remarks,
      CreatedBy,
      CreatedOnDate,
      CreatedAtTime,
      LastChangedBy,
      LastChangedDate,
      LastChangedTime
}
