@EndUserText.label : 'Knitting roll QC - defect codes'
@AbapCatalog.enhancement.category : #NOT_EXTENSIBLE
@AbapCatalog.tableCategory : #TRANSPARENT
@AbapCatalog.deliveryClass : #C
@AbapCatalog.dataMaintenance : #ALLOWED
define table zknit_qc_defect {

  key mandt          : mandt not null;
  key werks          : werks_d not null;
  key dcode          : abap.char(4) not null;

  descr              : abap.char(40);
  sortno             : abap.numc(3);
  inactive           : abap.char(1);

}
