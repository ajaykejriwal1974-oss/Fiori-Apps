@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Gate Pass Register - Cube'
@Analytics: { dataCategory: #CUBE, dataExtraction.enabled: true }
@Metadata.allowExtensions: true
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
