@EndUserText.label: 'Value help - Greige Lot, open QC'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
@Search.searchable: true
// NOT YET CREATED IN KSD. Ready to paste into Eclipse if wanted - see the
// note at the bottom of NEXT-STEPS.md.
//
// Value help for the Greige Lot field. Same open-lot test and same Plant
// binding as ZI_VH_QC_BATCH.
//
// Why this exists as well as ZI_VH_QC_BATCH: GreigeLot is QALS-CHARG on a
// type 01 or 08 lot only, so this list holds just the supplier/greige lots.
// ZI_VH_QC_BATCH is wider - it also carries the CHARG of type 89 in-process
// lots, which are the plant's own batch numbers, not anything a supplier sent.
// On a greige lot the two views return the same string for the same lot.
//
// Counts on 2026-08-29: 86 open lots carry a greige lot (85 in plant 1000,
// 1 in plant 2002), against 16 distinct batches in ZI_VH_QC_BATCH.
define view entity ZI_VH_QC_GREIGE_LOT
  as select from ZI_QC_INSP_LOT
{
      @EndUserText.label: 'Plant'
  key Plant,
      @EndUserText.label: 'Greige Lot'
      @Search.defaultSearchElement: true
  key GreigeLot,
      @EndUserText.label: 'Material'
      max(Material)     as Material,
      @EndUserText.label: 'Description'
      max(MaterialName) as MaterialName,
      @EndUserText.label: 'Open Lots'
      count(*)          as OpenLotCount
}
where
      IsOpen    =  'X'
  and GreigeLot <> ''
group by
  Plant,
  GreigeLot
