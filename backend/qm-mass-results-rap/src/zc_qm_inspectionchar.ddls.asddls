@EndUserText.label: 'QM Open Inspection Characteristics - Projection'
@AccessControl.authorizationCheck: #CHECK
@Metadata.allowExtensions: true
@Search.searchable: true
@ObjectModel.semanticKey: ['InspectionLot', 'InspectionOperation', 'InspectionCharacteristic']
define root view entity ZC_QM_InspectionChar
  provider contract transactional_query
  as projection on ZI_QM_InspectionChar
{
  key InspectionLot,
  key InspectionOperation,
  key InspectionCharacteristic,
      @Search.defaultSearchElement: true
      CharacteristicDescription,
      Material,
      Plant,
      WorkCenter,
      Unit,
      ResultValue,
      Valuation,
      InspectionType,
      Origin
}
