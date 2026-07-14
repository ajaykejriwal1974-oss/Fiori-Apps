@EndUserText.label: 'Packing Material Master - Projection'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
@Search.searchable: true
@ObjectModel.semanticKey: ['PackingType', 'WorkCenter', 'Material']
// Value helps reference standard released VH CDS (VERIFY the exact name per
// release); shade fields use the Shade master ZC_DD_Shade.
define root view entity ZC_PackingMaterial
  provider contract transactional_query
  as projection on ZI_PackingMaterial
{
  key PackingType,
  key WorkCenter,
      @Consumption.valueHelpDefinition: [{ entity: { name: 'I_MaterialStdVH', element: 'Material' } }]
  key Material,
      @Search.defaultSearchElement: true
      StorageLocation,
      Batch,
      Sequence
}
