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
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'QC: order and batch behind a lot'
// One row per inspection lot, holding the order it belongs to and the batch it
// is inspecting. Both resolutions happen here so that ZI_QC_INSP_LOT can join
// on plain fields rather than on expressions - CDS support for a CASE inside a
// join condition is far less certain than in a select list.
//
// Two sources are tried, and which one answered is published rather than
// hidden, because a technician deserves to know whether the app read a value
// off the lot or inferred it.
//
// OrderSource
//   'O'  the lot carries the order itself - in-process lots, types 03 and 04
//   'G'  derived from the greige lot through ZPP_BATCHN - Grey QC
//   ' '  no order found: this greige lot is not in any batch yet
//
// BatchSource
//   'C'  QALS-CHARG matched a plant batch number directly
//   'G'  taken from the greige lot's batch - indicative only, since one greige
//        lot is normally split across several batches
//   ' '  no batch resolved - the app must let the operator pick one from the
//        order's batches before anything can be confirmed
// TWO LOT NUMBERS, NOT ONE (2026-08-28)
// -------------------------------------
// QALS-CHARG is the lot as RECEIVED - exposed as Batch on ZI_QC_INSP_LOT.
// ZPP_BATCHN-LOTNO is the lot it is dyed UNDER. They are not the same number,
// because the 301 transfer from DRM1 to DPR1 renames the yarn on its way to
// the floor:
//
//   T11072BCXXXXXXXXXX / AT1-5547  ->  T11072BCXXXXXXXXXX / BCT
//   T1505T34TXXTEST    / TEST123   ->  T1505T34TXXTEST    / 3254-TEST
//
// ProductionLot is therefore NOT defaulted to the lot's own batch. Blank means
// "no plant batch record links to this lot yet", which is an honest answer a
// technician can act on. Echoing CHARG back would look like an answer and be
// wrong every time the rename applies. GreigeLot keeps its old fallback so the
// two in-process screens do not lose a field they already show.
define view entity ZI_QC_LOT_ORDER
  as select from qals as lot
    left outer join ZI_QC_BATCH_BY_GREIGE as bg on  bg.Plant     = lot.werk
                                                and bg.GreigeLot = lot.charg
    left outer join ZI_QC_BATCH_BY_NO     as bn on  bn.Plant       = lot.werk
                                                and bn.BatchNumber = lot.charg
{
  key lot.prueflos                                  as InspectionLot,
      lot.werk                                      as Plant,

      case when lot.aufnr <> ''  then lot.aufnr
           when bn.ProductionOrder is not null then bn.ProductionOrder
                                 else bg.ProductionOrder
      end                                           as ProductionOrder,
      case when lot.aufnr <> ''  then cast( 'O' as abap.char(1) )
           when bg.ProductionOrder is not null
            and bg.ProductionOrder <> '' then cast( 'G' as abap.char(1) )
                                 else cast( ' ' as abap.char(1) )
      end                                           as OrderSource,

      case when bn.BatchNumber is not null then bn.BatchNumber
                                           else bg.PlantBatch
      end                                           as PlantBatch,
      case when bn.BatchNumber is not null then bn.FiscalYear
                                           else bg.PlantBatchYear
      end                                           as PlantBatchYear,
      case when bn.BatchNumber is not null then cast( 'C' as abap.char(1) )
           when bg.PlantBatch  is not null then cast( 'G' as abap.char(1) )
                                           else cast( ' ' as abap.char(1) )
      end                                           as BatchSource,

      // The lot this delivery is dyed under - ZPP_BATCHN-LOTNO. No fallback:
      // blank means nothing links yet.
      case when bn.GreigeLot is not null then bn.GreigeLot
           when bg.GreigeLot is not null then bg.GreigeLot
                                         else cast( '' as abap.char(10) )
      end                                           as ProductionLot,

      // The greige lot under inspection. For Grey QC that is the lot's own
      // batch; for an in-process lot it comes from the plant batch record.
      case when bn.GreigeLot is not null then bn.GreigeLot
                                         else lot.charg
      end                                           as GreigeLot,

      bg.BatchCount                                 as GreigeBatchCount,
      bn.YearCount                                  as BatchYearCount
}
