@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'QC Inspection Lot - Interface'
@Metadata.allowExtensions: true
@ObjectModel.semanticKey: ['InspectionLot']
// Worklist over the standard QM inspection lot header QALS.
//
// Field names verified against DD03L on 2026-08-21, not assumed:
//   PRUEFLOS  key, NUMC 12      LICHN     vendor batch, CHAR 15 (NOT LICHA)
//   WERK      plant             KTEXTMAT  material short text, CHAR 40
//   ART       inspection type   LOSMENGE  QUAN, unit in MENGENEINH
//   HERKUNFT  lot origin        GESSTICHPR sample size, unit in EINHPROBE
//   STAT34    results confirmed STAT35    usage decision made
//
// ZPP_BATCHN is reached by ASSOCIATION, never by join. A join on AUFNR would
// multiply rows whenever one production order carries several plant batches,
// and a silently duplicated worklist is worse than a missing column.
define root view entity ZI_QC_INSP_LOT
  as select from qals as lot
    left outer join t001k as vcc on vcc.bwkey = lot.werk
  // Composition, not association: the technician edits result rows inside the
  // lot, and RAP only allows an updatable child within a composition.
  composition [0..*] of ZI_QC_INSP_CHAR as _Characteristic
{
  key lot.prueflos                                as InspectionLot,
      lot.werk                                    as Plant,
      vcc.bukrs                                   as CompanyCode,
      lot.art                                     as InspectionType,
      lot.herkunft                                as LotOrigin,
      lot.matnr                                   as Material,
      lot.ktextmat                                as MaterialName,
      lot.charg                                   as Batch,
      lot.lichn                                   as VendorBatch,
      lot.aufnr                                   as ProductionOrder,
      lot.ktextlos                                as LotText,
      lot.enstehdat                               as CreatedOn,
      lot.pastrterm                               as StartDate,
      lot.paendterm                               as EndDate,
      @Semantics.quantity.unitOfMeasure: 'LotUnit'
      lot.losmenge                                as LotQuantity,
      lot.mengeneinh                              as LotUnit,
      @Semantics.quantity.unitOfMeasure: 'SampleUnit'
      lot.gesstichpr                              as SampleSize,
      lot.einhprobe                               as SampleUnit,
      lot.stat34                                  as ResultsConfirmed,
      lot.stat35                                  as UsageDecisionMade,
      // A lot is open for the technician while results are not yet confirmed.
      case when lot.stat34 = 'X' then cast('' as abap.char(1))
                                 else cast('X' as abap.char(1))
      end                                         as IsOpen,
      _Characteristic
}
where lot.art in ( 'Z01', 'Z03', 'Z04', '01', '03', '04' )
