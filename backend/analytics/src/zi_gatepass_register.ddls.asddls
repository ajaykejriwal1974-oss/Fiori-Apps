@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Gate Pass Register - Cube'
@Analytics: { dataCategory: #CUBE, dataExtraction.enabled: true }
@Metadata.allowExtensions: true
// Analytical cube over ZGP_HDR/ZGP_ITEM (the MM gate pass, i.e. the gate-pass-rap
// model). Replaces the gate-pass ENTRY report variants
// (ZCRPT_GATEPASS_ENTRY / ZCRPT_GATEPASS_ENTRY_NON_RET, i.e. returnable vs
// non-returnable, plus the ZGATER/ZGATERE/ZGATENR/ZGREPT* tcodes over this model):
// the old report split becomes the GatePassType (DTYPE) dimension; aggregate in
// the query. NB the Z001 SD-delivery gate pass (ZGATEPASS_HDR/ITEM, tcode
// ZGATEPASS_REPT) is a SEPARATE data model - a second register if the business
// still uses it.
define view entity ZI_GATEPASS_REGISTER
  as select from zgp_hdr as Header
    inner join   zgp_item as Item
      on  Header.gpnum = Item.gpnum
      and Header.mjahr = Item.mjahr
{
  key Header.gpnum        as GatePassNumber,
  key Header.mjahr        as GatePassYear,
  key Item.zitem          as GatePassItem,
      Header.dtype        as GatePassType,
      Header.werks        as Plant,
      Header.dept         as Department,
      Header.vhnum        as VehicleNumber,
      Header.gindat       as GateInDate,
      Header.gotdat       as GateOutDate,
      Item.matnr          as Material,
      Item.maktx          as MaterialDescription,
      Item.lifnr          as Supplier,
      Item.name1          as SupplierName,
      @Semantics.quantity.unitOfMeasure: 'GatePassUnit'
      @DefaultAggregation: #SUM
      Item.gp_quan        as GatePassQuantity,
      Item.gp_meins       as GatePassUnit,
      Header.cre_user     as CreatedByUser,
      Header.erdat        as CreatedOn,
      @DefaultAggregation: #SUM
      @EndUserText.label: 'Record Count'
      cast( 1 as abap.int4 ) as RecordCount
}
