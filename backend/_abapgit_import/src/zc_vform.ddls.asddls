@EndUserText.label: 'Vendor Invoice Allocation - Projection'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
@Search.searchable: true
@ObjectModel.semanticKey: ['InvoiceNumber']
define root view entity ZC_VFORM
  provider contract transactional_query
  as projection on ZI_VFORM
{
      @Search.defaultSearchElement: true
      @Search.fuzzinessThreshold: 0.8
  key InvoiceNumber,
      PurchasingDocument,
      ReferenceNumber,
      @Search.defaultSearchElement: true
      Supplier,
      @Search.defaultSearchElement: true
      SupplierName,
      InvoiceDate,
      InvoiceValue,
      AllocatedValue,
      UnallocatedValue,
      AllocatedFlag,
      FormType,
      FormNumber,
      FormDate,
      FormValue,
      Quantity,
      CourierName,
      CourierDetail
}
