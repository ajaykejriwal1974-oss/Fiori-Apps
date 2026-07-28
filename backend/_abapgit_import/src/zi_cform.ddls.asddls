@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'C-Form Allocation Master - Interface'
@Metadata.allowExtensions: true
// Custom master (Route 7) - managed RAP over legacy table ZCFORM1 (ZCFORM1/ZFORM/ZFORMS/ZPCFORM).
// Field list mirrors the real Z-table (field dictionary). This legacy table
// has no TIMESTAMPL column, so the optimistic-concurrency ETag is omitted
// (add a TIMESTAMPL column to enable it). Code fields carry in-table text
// (@ObjectModel.text.element) and value helps (on the projection).
define root view entity ZI_Cform
  as select from zcform1
{
  key sale_org               as SalesOrganization,
  key cust_code              as Customer,
  key invoice_no             as BillingDocument,
      invoice_dt             as BillingDate,
      cast(invoice_val as abap.dec(23,2)) as InvoiceValue,
      form_type              as FormType,
      form_no                as FormNumber,
      form_dt                as FormDate,
      cast(allocated_value as abap.dec(23,2)) as AllocatedValue,
      cast(qty as abap.dec(23,3)) as Quantity
}
