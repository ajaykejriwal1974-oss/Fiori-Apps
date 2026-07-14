@EndUserText.label: 'Gate Pass - Projection (header)'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
@Search.searchable: true
@ObjectModel.semanticKey: ['GpNumber', 'FiscalYear']
define root view entity ZC_GatePass
  provider contract transactional_query
  as projection on ZI_GatePass
{
      @Search.defaultSearchElement: true
  key GpNumber,
  key FiscalYear,
      DocumentType,
      Plant,
      Department,
      VehicleNumber,
      InDate,
      InTime,
      OutDate,
      OutTime,
      Remarks,
      CreatedByUser,
      CreatedBy,
      CreatedOnDate,
      CreatedAtTime,
      _Item : redirected to composition child ZC_GatePassItem
}
