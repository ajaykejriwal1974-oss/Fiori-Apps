@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Vendor Invoice Allocation - Interface'
@Metadata.allowExtensions: true
@ObjectModel.semanticKey: ['InvoiceNumber']
// Managed master over the existing legacy table ZVFORM2 ("ztable for cform").
// ZVFORM2's amount fields reference an EXTERNAL currency (rbkp.waers) and qty an
// external unit (rseg.bstme) - neither is a column of ZVFORM2, so the view supplies
// its own constant Currency ('INR') for the amounts, and exposes qty as a plain
// (read-only) number. VERIFY: 'INR' assumes single-currency vendor invoices; if
// multi-currency, join RBKP (belnr+gjahr) to source waers instead.
define root view entity ZI_VFORM
  as select from zvform2
{
  key invoice_no       as InvoiceNumber,
      purchase_doc     as PurchasingDocument,
      reference_no     as ReferenceNumber,
      vend_code        as Supplier,
      vend_name        as SupplierName,
      invoice_dt       as InvoiceDate,
      @Semantics.amount.currencyCode: 'Currency'
      invoice_val      as InvoiceValue,
      @Semantics.amount.currencyCode: 'Currency'
      allocated_value1 as AllocatedValue,
      @Semantics.amount.currencyCode: 'Currency'
      un_allot_val     as UnallocatedValue,
      allocate_chk     as AllocatedFlag,
      form_type        as FormType,
      form_no          as FormNumber,
      form_dt          as FormDate,
      @Semantics.amount.currencyCode: 'Currency'
      form_val         as FormValue,
      cast( qty as abap.dec( 13, 3 ) ) as Quantity,
      currier_name     as CourierName,
      currier_detail   as CourierDetail,
      cast( 'INR' as abap.cuky ) as Currency
}
