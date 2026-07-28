@EndUserText.label: 'Gate Pass Header - Projection'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
@ObjectModel.semanticKey: ['GpNumber', 'FiscalYear']
define root view entity ZC_GTPASS
  provider contract transactional_query
  as projection on ZI_GTPASS
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
      CreatedAtTime
}
