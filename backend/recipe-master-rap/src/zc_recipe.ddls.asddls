@EndUserText.label: 'Dyeing Recipe Master - Projection'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
@Search.searchable: true
@ObjectModel.semanticKey: ['Plant', 'GreyCode', 'DyeCode', 'ShadeCode', 'ItemNumber']
// Value helps reference standard released VH CDS (VERIFY the exact name per
// release); shade fields use the Shade master ZC_DD_Shade.
define root view entity ZC_Recipe
  provider contract transactional_query
  as projection on ZI_Recipe
{
      @Consumption.valueHelpDefinition: [{ entity: { name: 'I_PlantStdVH', element: 'Plant' } }]
  key Plant,
      @Consumption.valueHelpDefinition: [{ entity: { name: 'I_MaterialStdVH', element: 'Material' } }]
  key GreyCode,
      @Consumption.valueHelpDefinition: [{ entity: { name: 'I_MaterialStdVH', element: 'Material' } }]
  key DyeCode,
      @Consumption.valueHelpDefinition: [{ entity: { name: 'ZC_DD_Shade', element: 'ShadeCode' } }]
  key ShadeCode,
  key ItemNumber,
      @Search.defaultSearchElement: true
      GreyItemDesc,
      DyeItemDesc,
      @Consumption.valueHelpDefinition: [{ entity: { name: 'I_MaterialStdVH', element: 'Material' } }]
      Component,
      ComponentDesc,
      ComponentType,
      Ratio,
      @Consumption.valueHelpDefinition: [{ entity: { name: 'I_UnitOfMeasureStdVH', element: 'UnitOfMeasure' } }]
      SalesUnit,
      Remarks,
      CreatedBy,
      CreatedOnDate,
      CreatedAtTime,
      LastChangedBy,
      LastChangedDate,
      LastChangedTime
}
