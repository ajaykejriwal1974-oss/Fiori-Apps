@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Gate Pass - Interface (item)'
@Metadata.allowExtensions: true
define view entity ZI_GATEPASS_ITEM
  as select from zgp_item
  association to parent ZI_GATEPASS as _GatePass on  $projection.GpNumber  = _GatePass.GpNumber
                                                 and $projection.FiscalYear = _GatePass.FiscalYear
{
  key gpnum                  as GpNumber,
  key zitem                  as ItemNumber,
  key mjahr                  as FiscalYear,
      matnr                  as Material,
      maktx                  as MaterialDescription,
      lifnr                  as Supplier,
      name1                  as SupplierName,
      cast(gp_quan as abap.dec(23,3)) as Quantity,
      gp_meins               as Unit,
      _GatePass
}
