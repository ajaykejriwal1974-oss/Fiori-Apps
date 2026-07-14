@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Gate Pass Item - Interface'
@Metadata.allowExtensions: true
@ObjectModel.semanticKey: ['GpNumber', 'ItemNumber', 'FiscalYear']
define root view entity ZI_GTPASS_ITEM
  as select from zgp_item
{
  key gpnum                  as GpNumber,
  key zitem                  as ItemNumber,
  key mjahr                  as FiscalYear,
      matnr                  as Material,
      maktx                  as MaterialDescription,
      lifnr                  as Supplier,
      name1                  as SupplierName,
      cast(gp_quan as abap.dec(23,3)) as Quantity,
      gp_meins               as Unit
}
