@EndUserText.label: 'C-Form Allocation Master - Projection'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
@Search.searchable: true
@ObjectModel.semanticKey: ['SalesOrganization', 'Customer', 'BillingDocument']
// Value helps reference standard released VH CDS (VERIFY the exact name per
// release); shade fields use the Shade master ZC_DD_Shade.
define root view entity ZC_Cform
  provider contract transactional_query
  as projection on ZI_Cform
{
      @Consumption.valueHelpDefinition: [{ entity: { name: 'I_SalesOrganizationStdVH', element: 'SalesOrganization' } }]
  key SalesOrganization,
      @Consumption.valueHelpDefinition: [{ entity: { name: 'I_CustomerStdVH', element: 'Customer' } }]
  key Customer,
  key BillingDocument,
      @Search.defaultSearchElement: true
      BillingDate,
      InvoiceValue,
      FormType,
      FormNumber,
      FormDate,
      AllocatedValue,
      Quantity
}
