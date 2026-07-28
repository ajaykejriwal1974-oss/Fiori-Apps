@EndUserText.label: 'Gate Pass Item - Projection'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
@ObjectModel.semanticKey: ['GpNumber', 'ItemNumber', 'FiscalYear']
define root view entity ZC_GTPASS_ITEM
  provider contract transactional_query
  as projection on ZI_GTPASS_ITEM
{
  key GpNumber,
  key ItemNumber,
  key FiscalYear,
      Material,
      MaterialDescription,
      Supplier,
      SupplierName,
      Quantity,
      Unit
}
