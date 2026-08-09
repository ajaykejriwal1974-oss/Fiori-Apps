@EndUserText.label: 'Packing Units (existing HUs) - Projection'
@AccessControl.authorizationCheck: #CHECK
@Metadata.allowExtensions: true
@Search.searchable: true
@ObjectModel.semanticKey: ['HandlingUnit']
define root view entity ZC_PACKING_UNIT
  provider contract transactional_query
  as projection on ZI_PACKING_UNIT
{
      @Search.defaultSearchElement: true
  key HandlingUnit,
      Reference,
      PackagingMaterial,
      NetWeight,
      GrossWeight,
      WeightUnit,
      PackingGroup
}
