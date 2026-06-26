@EndUserText.label: 'Packing Material Master - Projection'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
@Search.searchable: true
@ObjectModel.semanticKey: ['PackingMaterial']
define root view entity ZC_PackMaterial
  provider contract transactional_query
  as projection on ZI_PackMaterial
{
  key PackingMaterial,
      @Search.defaultSearchElement: true
      Description,
      PackType,
      TareWeight,
      WeightUnit,
      IsActive,
      CreatedBy,
      CreatedAt,
      LastChangedBy,
      LastChangedAt,
      LocalLastChangedAt
}
