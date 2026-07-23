@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Vendor Invoice Allocation - Interface'
@Metadata.allowExtensions: true
@ObjectModel.semanticKey: ['InvoiceNumber']
// Managed master over the existing legacy table ZVFORM2 ("ztable for cform" - the
// vendor-side twin of ZCFORM1 behind cform-master). Clean-core replacement for
// ZVFORM (vendor invoice) + ZVFORMS (allocate vendor invoice). Single flat entity.
// Amount fields are exposed as plain values (ZVFORM2 carries no currency key), as
// cform-master does.
define root view entity ZI_VFORM
  as select from zvform2
{
  key invoice_no       as InvoiceNumber,
      purchase_doc     as PurchasingDocument,
      reference_no     as ReferenceNumber,
      vend_code        as Supplier,
      vend_name        as SupplierName,
      invoice_dt       as InvoiceDate,
      invoice_val      as InvoiceValue,
      allocated_value1 as AllocatedValue,
      un_allot_val     as UnallocatedValue,
      allocate_chk     as AllocatedFlag,
      form_type        as FormType,
      form_no          as FormNumber,
      form_dt          as FormDate,
      form_val         as FormValue,
      qty              as Quantity,
      currier_name     as CourierName,
      currier_detail   as CourierDetail
}
