@EndUserText.label: 'QC - Single Result Parameter'
// Flat parameter, deliberately. RAP action parameters are simplest when they
// are flat abstract entities, and one call per changed characteristic inside a
// single $batch is cheap. A deep table parameter would be fewer round trips
// but reintroduces exactly the kind of structural dependency that cost us the
// composition.
define abstract entity ZD_QC_SINGLE_RESULT
{
      @EndUserText.label: 'Inspection Lot'
  InspectionLot        : abap.numc(12);
      @EndUserText.label: 'Operation'
  OperationNumber      : abap.numc(8);
      @EndUserText.label: 'Characteristic'
  CharacteristicNumber : abap.numc(4);
      @EndUserText.label: 'Mean Value'
  MeanValue            : abap.fltp;
      @EndUserText.label: 'Code Group'
  ResultCodeGroup      : abap.char(8);
      @EndUserText.label: 'Code'
  ResultCode           : abap.char(4);
      @EndUserText.label: 'Defects Found'
  DefectCount          : abap.int4;
      @EndUserText.label: 'Sample Inspected'
  ActualSampleSize     : abap.int4;
      @EndUserText.label: 'Comment'
  ResultComment        : abap.char(40);
}
