@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Credit/Debit Note Register - Cube'
@Analytics: { dataCategory: #CUBE, dataExtraction.enabled: true }
@Metadata.allowExtensions: true
// Analytical cube for the FI Credit/Debit Note register. Replaces the FI ALV/print
// reports ZCRDRNOTE (ZCRPT_FI_R001), ZCRDRPN (ZRPT_FI_CRDR) and ZCDQD.
// None of those has a persisted Z-table (classification: source = "—"), so the cube
// is based on the real clean-core FI source: the Universal Journal ACDOCA.
// Restricted to the leading ledger (RLDNR = '0L') to avoid double-counting across
// parallel ledgers. Old report variants (customer note / vendor note / ALV / print)
// become dimensions — slice on DocumentType, DebitCreditCode, Customer/Supplier.
//
// VERIFY: the legacy reports filter to specific credit/debit-note document types
// (customer-defined BLART, e.g. DG/DA credit & debit memos). Those doc types are not
// known from the dictionary, so the cube is left unfiltered on BLART and exposes
// DocumentType as a free dimension. Add `where blart in ( ... )` here once the real
// credit/debit-note document types are confirmed on KSD.
define view entity ZI_CRDR_NOTE
  as select from acdoca
{
  key rbukrs                           as CompanyCode,
  key gjahr                            as FiscalYear,
  key belnr                            as AccountingDocument,
  key docln                            as LedgerGLLineItem,
      blart                            as DocumentType,
      drcrk                            as DebitCreditCode,
      budat                            as PostingDate,
      bldat                            as DocumentDate,
      racct                            as GLAccount,
      kunnr                            as Customer,
      lifnr                            as Supplier,
      rhcur                            as CompanyCodeCurrency,
      @DefaultAggregation: #SUM
      cast( hsl as abap.dec( 23, 2 ) ) as AmountInCoCodeCrcy,
      @DefaultAggregation: #SUM
      @EndUserText.label: 'Record Count'
      cast( 1 as abap.int4 )           as RecordCount
}
where rldnr = '0L'
