@EndUserText.label: 'Packing Material Master - Projection'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
@Search.searchable: true
@ObjectModel.semanticKey: ['PackingType', 'WorkCenter', 'Material']
define root view entity ZC_PackingMaterial
  provider contract transactional_query
  as projection on ZI_PackingMaterial
{
  key PackingType,
  key WorkCenter,
  key Material,
      @Search.defaultSearchElement: true
      StorageLocation,
      Batch,
      Sequence
}
