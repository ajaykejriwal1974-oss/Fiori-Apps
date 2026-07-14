@EndUserText.label: 'Gate Pass - Projection (item)'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
define view entity ZC_GatePassItem
  as projection on ZI_GatePassItem
{
  key GpNumber,
  key ItemNumber,
  key FiscalYear,
      Material,
      MaterialDescription,
      Supplier,
      SupplierName,
      Quantity,
      Unit,
      _GatePass : redirected to parent ZC_GatePass,
      _Part     : redirected to ZC_GatePassPart
}
