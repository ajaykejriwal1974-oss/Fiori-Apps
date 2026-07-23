@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Job-Work Challan Register - Cube'
@Analytics: { dataCategory: #CUBE, dataExtraction.enabled: true }
@Metadata.allowExtensions: true
// Analytical cube for the Job-Work Challan register. Replaces ZJWCHLN (ZCRPT_MM_R01)
// over the Z-table ZCTA_MM_JOB (links material document MBLNR to the outbound
// delivery VBELN), joined to the material-document items MSEG for material / qty /
// plant / movement / vendor. Quantity cast to plain decimal.
// VERIFY: ZCTA_MM_JOB has no material-doc year, so the join to MSEG is on MBLNR only
// (material doc numbers are effectively year-unique here); add MJAHR to ZCTA_MM_JOB
// if cross-year collisions are possible.
define view entity ZI_JOBWORK_CHALLAN
  as select from zcta_mm_job as job
    inner join mseg on job.mblnr = mseg.mblnr
{
  key job.mblnr                          as MaterialDocument,
  key mseg.mjahr                         as MaterialDocYear,
  key mseg.zeile                         as MaterialDocItem,
      job.vbeln                          as OutboundDelivery,
      mseg.bwart                         as MovementType,
      mseg.matnr                         as Material,
      mseg.werks                         as Plant,
      mseg.lgort                         as StorageLocation,
      mseg.lifnr                         as Supplier,
      mseg.budat_mkpf                    as PostingDate,
      @Semantics.unitOfMeasure: true
      mseg.meins                         as BaseUnit,
      @DefaultAggregation: #SUM
      cast( mseg.menge as abap.dec( 15, 3 ) ) as Quantity,
      @DefaultAggregation: #SUM
      @EndUserText.label: 'Record Count'
      cast( 1 as abap.int4 )             as RecordCount
}
