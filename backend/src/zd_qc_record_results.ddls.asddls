@EndUserText.label: 'QC - Record Results Parameter'
define abstract entity ZD_QC_RECORD_RESULTS
{
      @EndUserText.label: 'Inspection Lot'
  InspectionLot   : abap.numc(12);
      @EndUserText.label: 'Operation'
  OperationNumber : abap.numc(8);
      @EndUserText.label: 'Inspector Comment'
  // Not 'Comment' - COMMENT is a reserved word in CDS.
  ResultComment   : abap.char(40);
}
