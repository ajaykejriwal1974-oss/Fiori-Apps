@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'E-Invoice/E-Way Audit Log - Cube'
@Analytics: { dataCategory: #CUBE, dataExtraction.enabled: true }
@Metadata.allowExtensions: true
// Analytical cube for the e-invoice / e-way-bill audit log. Replaces ZAUDIT_LOG
// (program ZAUDIT_LOG) over the real Z-table ZEINV_AUDITLOG. Read-only register of
// IRN / e-way status per billing document.
define view entity ZI_AUDIT_LOG
  as select from zeinv_auditlog
{
  key bukrs             as CompanyCode,
  key bupla             as BusinessPlace,
  key vbeln             as BillingDocument,
      irn               as IRN,
      irn_status        as IRNStatus,
      ebillno           as EWayBillNumber,
      doc_date          as DocumentDate,
      odn               as OfficialDocNumber,
      odn_date          as OfficialDocDate,
      seller_gstin      as SellerGSTIN,
      extract_on        as ExtractedOn,
      extract_by        as ExtractedBy,
      cancel_on         as CancelledOn,
      cancel_by         as CancelledBy,
      cancel_reason     as CancellationReason,
      @DefaultAggregation: #SUM
      @EndUserText.label: 'Record Count'
      cast( 1 as abap.int4 ) as RecordCount
}
