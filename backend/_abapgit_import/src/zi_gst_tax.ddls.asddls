@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'GST Tax Register - Cube'
@Analytics: { dataCategory: #CUBE, dataExtraction.enabled: true }
@Metadata.allowExtensions: true
// Analytical cube over VBRK (billing header). Replaces: ZGST, ZGST1, ZGST2, ZGSTCR.
// NOTE: the original reports typed their output on structure ZSOL_GST_DET (GSTIN/state
// derivation work area) and read billing VBRK/VBRP + ZKIL_VBRK append + ZZGATEPASS.
// None of those is a persisted Z-table, so the cube is based on the real source: VBRK.
// GSTIN/state master derivation (ZSOL_GST_DET) and the CGST/SGST/IGST condition split
// (tax conditions) are not modelled here. Old report variants are now dimensions;
// aggregate in the query.
define view entity ZI_GST_TAX
  as select from vbrk
{
  key bukrs            as CompanyCode,
  key vbeln            as BillingDocument,
      fkart            as BillingType,
      vkorg            as SalesOrg,
      bupla            as BusinessPlace,
      regio            as Region,
      kunag            as SoldToParty,
      kunrg            as Payer,
      stceg            as VatRegistration,
      fkdat            as BillingDate,
      fksto            as Cancelled,
      zz_exnum         as SalesDocument,
      waerk            as Currency,
      @DefaultAggregation: #SUM
      cast( netwr as abap.dec( 15, 3 ) ) as NetValue,
      @DefaultAggregation: #SUM
      cast( mwsbk as abap.dec( 15, 3 ) ) as TaxAmount,
      @DefaultAggregation: #SUM
      @EndUserText.label: 'Record Count'
      cast( 1 as abap.int4 ) as RecordCount
}
