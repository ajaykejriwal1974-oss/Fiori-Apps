@EndUserText.label: 'C-Form Allocation Master - Projection'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
@Search.searchable: true
@ObjectModel.semanticKey: ['SalesOrganization', 'Customer', 'BillingDocument']
define root view entity ZC_Cform
  provider contract transactional_query
  as projection on ZI_Cform
{
  key SalesOrganization,
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
