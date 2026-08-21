@EndUserText.label: 'QC Characteristic - Projection'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
define view entity ZC_QC_INSP_CHAR
  as projection on ZI_QC_INSP_CHAR
{
  key InspectionLot,
  key OperationNumber,
  key CharacteristicNumber,
      @EndUserText.label: 'MIC'
      MasterCharacteristic,
      @EndUserText.label: 'Characteristic'
      CharacteristicName,
      @EndUserText.label: 'Kind'
      CharacteristicKind,
      @EndUserText.label: 'Unit'
      CharacteristicUnit,
      @EndUserText.label: 'Decimals'
      DecimalPlaces,
      @EndUserText.label: 'Target'
      TargetValue,
      TargetIsInitial,
      @EndUserText.label: 'Lower Limit'
      LowerLimit,
      LowerLimitIsInitial,
      @EndUserText.label: 'Upper Limit'
      UpperLimit,
      UpperLimitIsInitial,
      @EndUserText.label: 'Selected Set'
      SelectedSet,
      CatalogType,
      @EndUserText.label: 'Result'
      MeanValue,
      MeanIsInitial,
      @EndUserText.label: 'Code'
      ResultCode,
      ResultCodeGroup,
      @EndUserText.label: 'Defects Found'
      DefectCount,
      @EndUserText.label: 'Sample Inspected'
      ActualSampleSize,
      @EndUserText.label: 'Valuation'
      Valuation,
      @EndUserText.label: 'Inspector'
      Inspector,
      @EndUserText.label: 'Inspected On'
      InspectionDate,
      @EndUserText.label: 'Comment'
      InspectorComment,
      ResultStatus
}
