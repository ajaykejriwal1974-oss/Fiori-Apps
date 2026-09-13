@EndUserText.label: 'QC - Release Greige to Production Parameter'
// Parameter for releaseToProduction, the follow-on step of Grey QC.
//
// The movement this posts is the one plant 2002 actually uses: 301 from DRM1
// "RM Dyg Main St-1" to DPR1 "Dyg Prod RM St-1". Verified against MSEG rather
// than assumed - 311 was my first guess and it has been used six times in the
// history of the plant, against 301 every week.
//
// ToBatch is the field that guess missed. The transfer does not just move the
// yarn, it renames it: the supplier batch in DRM1 becomes the production
// greige lot in DPR1, and that lot is what ZPP_BATCHN-LOTNO holds.
//
//   T11072BCXXXXXXXXXX / AT1-5547  ->  T11072BCXXXXXXXXXX / BCT
//   T1505T34TXXTEST    / TEST123   ->  T1505T34TXXTEST    / 3254-TEST
//
// Same material, new batch. Without ToBatch the yarn arrives on the production
// floor under a batch nothing downstream recognises.
//
// Movement type and both locations stay parameters rather than constants so a
// second plant needs no code change; the app defaults them and the technician
// does not normally see them.
define abstract entity ZD_QC_RELEASE_PROD
{
      @EndUserText.label: 'Inspection Lot'
  InspectionLot        : abap.numc(12);
      @EndUserText.label: 'Material'
  Material             : abap.char(40);
      @EndUserText.label: 'Batch'
  Batch                : abap.char(10);
      @EndUserText.label: 'Greige Lot to Create'
  ToBatch              : abap.char(10);
      @EndUserText.label: 'Plant'
  Plant                : abap.char(4);
      @EndUserText.label: 'Movement Type'
  MovementType         : abap.char(3);
      @EndUserText.label: 'From Storage Location'
  FromStorageLocation  : abap.char(4);
      @EndUserText.label: 'To Storage Location'
  ToStorageLocation    : abap.char(4);
      @EndUserText.label: 'Quantity'
  Quantity             : abap.quan(13,3);
      @EndUserText.label: 'Unit'
  Unit                 : abap.unit(3);
      @EndUserText.label: 'Posting Date'
  PostingDate          : abap.dats;
      @EndUserText.label: 'Header Text'
  HeaderText           : abap.char(25);
}
