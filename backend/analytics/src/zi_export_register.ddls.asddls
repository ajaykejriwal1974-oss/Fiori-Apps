@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Export / Incentive Register - Cube'
@Analytics: { dataCategory: #CUBE, dataExtraction.enabled: true }
@Metadata.allowExtensions: true
// Analytical cube over ZEXP. Replaces: ZGCUDB (DEPB), export side of ZBRC/ZEXP.
// Old report variants are now dimensions; aggregate in the query.
define view entity ZI_ExportRegisterCube
  as select from zexp
{
  key vbeln            as BillingDocument,
  key kschl            as ConditionType,
      fkdat            as BillingDate,
      @DefaultAggregation: #SUM
      cast( kursk as abap.dec( 15, 3 ) ) as ExchangeRate,
      @DefaultAggregation: #SUM
      cast( netwr as abap.dec( 15, 3 ) ) as NetValue,
      waerk            as Currency,
      @DefaultAggregation: #SUM
      @EndUserText.label: 'Record Count'
      cast( 1 as abap.int4 ) as RecordCount
}
