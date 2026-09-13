@EndUserText.label: 'QC - Confirm Production Parameter'
// Parameter for confirmDyeing and confirmWinding. One structure serves both:
// they differ only in which operation of the order they confirm, and the
// action name already says which.
//
//   confirmDyeing   operation 0010, work centres DYG00001 / DYG00012
//   confirmWinding  operation 0020, work centre  WIN00025
//
// Both read from AFRU in plant 2002, not from the routing master - the routing
// already carries the second operation and both are being confirmed today.
//
// PlantBatch is mandatory even where the lot could resolve it. A confirmation
// posts quantity against one physical batch, and an order here routinely
// carries five or six. Where the lot resolved one the app pre-fills it; where
// it did not, the operator picked from the order's batches, and this is how
// that choice reaches the backend.
define abstract entity ZD_QC_CONFIRM_PROD
{
      @EndUserText.label: 'Inspection Lot'
  InspectionLot     : abap.numc(12);
      @EndUserText.label: 'Production Order'
  ProductionOrder   : abap.char(12);
      @EndUserText.label: 'Plant Batch'
  PlantBatch        : abap.char(10);
      @EndUserText.label: 'Fiscal Year'
  PlantBatchYear    : abap.numc(4);
      @EndUserText.label: 'Job Card'
  JobCard           : abap.char(10);
      @EndUserText.label: 'Operation'
  Operation         : abap.char(4);
      @EndUserText.label: 'Work Centre'
  WorkCentre        : abap.char(8);
      @EndUserText.label: 'Plant'
  Plant             : abap.char(4);
      @EndUserText.label: 'Yield Quantity'
  YieldQuantity     : abap.quan(13,3);
      @EndUserText.label: 'Scrap Quantity'
  ScrapQuantity     : abap.quan(13,3);
      @EndUserText.label: 'Unit'
  Unit              : abap.unit(3);
      // ZPP_BATCHN-CHEESES is ZDE_CHEESES, QUAN 15 with no decimals - not an
      // integer, which is what I had here first.
      @EndUserText.label: 'Cheeses'
  Cheeses           : abap.quan(15,0);
      @EndUserText.label: 'Final Confirmation'
  FinalConfirmation : abap.char(1);
      @EndUserText.label: 'Posting Date'
  PostingDate       : abap.dats;
      @EndUserText.label: 'Confirmation Text'
  ConfirmationText  : abap.char(40);
}
