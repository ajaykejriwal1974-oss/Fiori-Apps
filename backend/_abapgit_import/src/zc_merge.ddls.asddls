@EndUserText.label: 'Merge Details Master - Projection'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
@Search.searchable: true
@ObjectModel.semanticKey: ['OrderNumber', 'Grade', 'EndUse']
// Value helps reference standard released VH CDS (VERIFY the exact name per
// release); shade fields use the Shade master ZC_DD_Shade.
define root view entity ZC_Merge
  provider contract transactional_query
  as projection on ZI_Merge
{
  key OrderNumber,
  key Grade,
  key EndUse,
      @Search.defaultSearchElement: true
      Batch,
      @Consumption.valueHelpDefinition: [{ entity: { name: 'ZC_DD_Shade', element: 'ShadeCode' } }]
      ShadeCode,
      Quantity,
      @Consumption.valueHelpDefinition: [{ entity: { name: 'ZC_DD_Shade', element: 'ShadeCode' } }]
      ShadeCode2
}
