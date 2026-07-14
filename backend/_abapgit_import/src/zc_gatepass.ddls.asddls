@EndUserText.label: 'Gate Pass - Projection (header)'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
@ObjectModel.semanticKey: ['GpNumber', 'FiscalYear']
define root view entity ZC_GATEPASS
  provider contract transactional_query
  as projection on ZI_GATEPASS
{
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
      _Item : redirected to composition child ZC_GATEPASS_ITEM
}
