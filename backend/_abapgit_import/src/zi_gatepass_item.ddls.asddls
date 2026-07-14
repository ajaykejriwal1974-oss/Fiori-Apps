@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Gate Pass - Interface (item)'
@Metadata.allowExtensions: true
// Gate-pass items over ZGP_ITEM. Child of ZI_GatePass on GpNumber + FiscalYear.
// ZGP_PART (inward receipt detail) is associated but NOT composed: it has no
// MJAHR key column, so it cannot join the parent's full key cleanly - exposed as
// a plain association (_Part) and flagged for a data-model fix before activating.
define view entity ZI_GatePassItem
  as select from zgp_item
  association        to parent ZI_GatePass     as _GatePass on  $projection.GpNumber  = _GatePass.GpNumber
                                                            and $projection.FiscalYear = _GatePass.FiscalYear
  association [0..*] to ZI_GatePassPart        as _Part     on  $projection.GpNumber  = _Part.GpNumber
                                                            and $projection.ItemNumber = _Part.ItemNumber
{
  key gpnum                  as GpNumber,
  key zitem                  as ItemNumber,
  key mjahr                  as FiscalYear,
      matnr                  as Material,
      maktx                  as MaterialDescription,
      lifnr                  as Supplier,
      name1                  as SupplierName,
      @Semantics.quantity.unitOfMeasure: 'Unit'
      gp_quan                as Quantity,
      @Semantics.unitOfMeasure: true
      gp_meins               as Unit,
      _GatePass,
      _Part
}
