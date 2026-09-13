@EndUserText.label: 'Value help - Batch, open QC inspections'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
@Search.searchable: true
// Value help for the Batch field on the three QC worklists.
//
// "Open" is IsOpen from ZI_QC_INSP_LOT: QALS-STAT34 not set, results not yet
// confirmed. That is the same test the worklists use.
//
// Deliberately NOT ZPP_BATCHN-CLOSED, which was the first thing asked for.
// Of 131,471 undeleted batches in plant 2002, seven are marked closed, so
// "not closed" is not a filter - it is the whole table. Checked 2026-08-29.
//
// InspectionType is a key, not just a field. Each app reads one stage - Grey
// 01 and 08, Post-Dyeing 03, Post-Winding 04 - and without the type in the
// list every app offered every other app's batches. Post-Dyeing was showing
// raw-material batches its own worklist can never return. Measured
// 2026-08-29: no batch carries open lots of two types, so keying on type adds
// no duplicate rows, it only lets the app ask for its own.
//
// Plant is a key too, and bound to the Plant filter in ZC_QC_INSP_LOT, so the
// list narrows to whatever plant the operator is working in.
//
// Grouped rather than DISTINCT: one batch can raise several inspection lots,
// and a value help whose key repeats renders duplicate rows. OpenLotCount
// says how many are behind each entry.
//
// MaterialCount and OrderCount exist so the app can decide whether it is safe
// to auto-fill the Material and Production Order filters when a batch is
// picked. Material is NOT one per batch: measured 2026-08-29, 4 of the 16
// batches with open lots carry more than one (QM_TEST 3, F023000004 3,
// QM_TEST1 and QM_TEST4 2 each). Filling Material from max() on those would
// silently hide most of the batch's own lots. The app fills only where the
// count is 1; the same guard applies to ProductionOrder, blank on 15 of 16.
define view entity ZI_VH_QC_BATCH
  as select from ZI_QC_INSP_LOT
{
      @EndUserText.label: 'Plant'
  key Plant,
      @EndUserText.label: 'Inspection Type'
  key InspectionType,
      @EndUserText.label: 'Batch'
      @Search.defaultSearchElement: true
  key Batch,
      @EndUserText.label: 'Material'
      max(Material)                   as Material,
      @EndUserText.label: 'Description'
      max(MaterialName)               as MaterialName,
      @EndUserText.label: 'Materials'
      count(distinct Material)        as MaterialCount,
      @EndUserText.label: 'Production Order'
      max(ProductionOrder)            as ProductionOrder,
      @EndUserText.label: 'Orders'
      count(distinct ProductionOrder) as OrderCount,
      @EndUserText.label: 'Open Lots'
      count(*)                        as OpenLotCount
}
where
      IsOpen =  'X'
  and Batch  <> ''
group by
  Plant,
  InspectionType,
  Batch
