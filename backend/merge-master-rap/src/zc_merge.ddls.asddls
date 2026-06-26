@EndUserText.label: 'Merge Details Master - Projection'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
@Search.searchable: true
@ObjectModel.semanticKey: ['OrderNumber', 'Grade', 'EndUse']
define root view entity ZC_Merge
  provider contract transactional_query
  as projection on ZI_Merge
{
  key OrderNumber,
  key Grade,
  key EndUse,
      @Search.defaultSearchElement: true
      Batch,
      ShadeCode,
      Quantity,
      ShadeCode2
}
