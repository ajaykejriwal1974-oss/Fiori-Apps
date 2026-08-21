@EndUserText.label: 'QC - Usage Decision Parameter'
define abstract entity ZD_QC_USAGE_DECISION
{
      @EndUserText.label: 'Inspection Lot'
  InspectionLot : abap.numc(12);
      @EndUserText.label: 'UD Code Group'
  CodeGroup     : abap.char(8);
      @EndUserText.label: 'UD Code'
  Code          : abap.char(4);
      @EndUserText.label: 'Reason'
  Reason        : abap.char(40);
}
