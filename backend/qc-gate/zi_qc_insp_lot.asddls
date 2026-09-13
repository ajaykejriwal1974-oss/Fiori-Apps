// !! STALE AS OF 2026-08-28 - DO NOT PASTE THIS BACK INTO SAP !!
//
// This copy predates the LOTNO refactor and still uses field names that no
// longer exist (GreigeLot on ZI_QC_BATCH_JOB, GreigeLotCount on
// ZI_QC_ORDER_CONTEXT). Activating it would undo the fix and break the three
// QC apps, whose $select statements now read GreigeLotRef.
//
// The active version in KSD is the source of truth - read it with ADT rather
// than trusting this file. What changed and why: CHANGE-2026-08-28-lotno.md
//
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
// Order level and batch level are different things (2026-08-28)
// ------------------------------------------------------------
// An order is raised with a big quantity and split into many small batches.
// So the two levels answer different questions and are kept apart here:
//
//   ORDER  what has to be made, and against what specification. Grey QC hangs
//          off this, because a greige lot is judged against what the order
//          needs. Fields: GreigeMaterial, DyedMaterial, OrderQuantity,
//          OrderCheeses, and the counts that audit them.
//
//   BATCH  the physical thing that was dyed and wound. Post-Dyeing and
//          Post-Winding QC hang off this, because two batches off one order
//          can pass and fail differently. Fields: PlantBatch, JobCard,
//          BatchQuantity, BatchCheeses, DyeingWorkCentre, WindingWorkCentre.
//
// Every joined view is either keyed on the inspection lot or aggregated to one
// row per key, and the batch join uses ZPP_BATCHN's full key. Nothing here can
// multiply a lot - that is how the old "never join ZPP_BATCHN on AUFNR" rule
// survives while the flat columns the worklists need still appear.
define root view entity ZI_QC_INSP_LOT
  as select from qals as lot
    left outer join t001k               as vcc on vcc.bwkey        = lot.werk
    left outer join ZI_QC_LOT_ORDER     as lo  on lo.InspectionLot = lot.prueflos
    left outer join ZI_QC_ORDER_CONTEXT as oc  on  oc.Plant           = lot.werk
                                               and oc.ProductionOrder = lo.ProductionOrder
    left outer join ZI_QC_BATCH_JOB     as bj  on  bj.Plant       = lot.werk
                                               and bj.BatchNumber = lo.PlantBatch
                                               and bj.FiscalYear  = lo.PlantBatchYear
  // Plain association, deliberately NOT a composition. See the note in
  // ZI_QC_INSP_CHAR: the composition/to-parent pair is an activation cycle
  // this system would not resolve. Characteristics are read through this
  // association and written through the recordSingleResult action.
  association [0..*] to ZI_QC_INSP_CHAR as _Characteristic
    on $projection.InspectionLot = _Characteristic.InspectionLot
  // Every batch on this lot's order. Needed when BatchSource is blank - the
  // lot knows its order but not which of the order's batches it is inspecting,
  // so the operator picks from this list before a confirmation can be posted.
  association [0..*] to ZI_QC_BATCH_JOB as _OrderBatch
    on  $projection.Plant           = _OrderBatch.Plant
    and $projection.ProductionOrder = _OrderBatch.ProductionOrder
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

      // ---- order level: the specification -------------------------------
      lo.ProductionOrder                          as ProductionOrder,
      lo.OrderSource                              as OrderSource,
      lot.aufnr                                   as LotOrder,
      oc.GreigeMaterial                           as GreigeMaterial,
      oc.GreigeMaterialCount                      as GreigeMaterialCount,
      oc.DyedMaterial                             as DyedMaterial,
      oc.DyedMaterialCount                        as DyedMaterialCount,
      oc.GreigeLotCount                           as GreigeLotCount,
      oc.OrderQuantity                            as OrderQuantity,
      oc.OrderCheeses                             as OrderCheeses,
      oc.BatchCount                               as BatchCount,
      oc.OpenBatchCount                           as OpenBatchCount,
      oc.FirstBatchDate                           as FirstBatchDate,
      oc.LastBatchDate                            as LastBatchDate,

      // ---- batch level: the physical thing ------------------------------
      lo.PlantBatch                               as PlantBatch,
      lo.PlantBatchYear                           as PlantBatchYear,
      lo.BatchSource                              as BatchSource,
      lo.ProductionLot                            as ProductionLot,
      lo.GreigeLot                                as GreigeLot,
      lo.GreigeBatchCount                         as GreigeBatchCount,
      bj.JobCard                                  as JobCard,
      bj.JobCardCount                             as JobCardCount,
      bj.ScheduleNumber                           as ScheduleNumber,
      bj.BatchDate                                as BatchDate,
      @Semantics.quantity.unitOfMeasure: 'BatchUnit'
      bj.BatchQuantity                            as BatchQuantity,
      bj.BatchUnit                                as BatchUnit,
      bj.Cheeses                                  as BatchCheeses,
      bj.DyeingWorkCentre                         as DyeingWorkCentre,
      bj.WindingWorkCentre                        as WindingWorkCentre,
      bj.BatchClosed                              as BatchClosed,
      bj.BatchAssigned                            as BatchAssigned,

      _Characteristic,
      _OrderBatch
}
