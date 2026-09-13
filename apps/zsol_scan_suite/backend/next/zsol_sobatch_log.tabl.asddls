@EndUserText.label : 'Scan Suite: sales order batch assignment log'
@AbapCatalog.enhancement.category : #NOT_EXTENSIBLE
@AbapCatalog.tableCategory : #TRANSPARENT
@AbapCatalog.deliveryClass : #A
@AbapCatalog.dataMaintenance : #RESTRICTED
define table zsol_sobatch_log {
  key mandt    : mandt not null;
  key logid    : sysuuid_x16 not null;
  vbeln        : vbeln_va;
  posnr        : posnr_va;
  charg        : charg_d;
  action       : abap.char(1);
  app_user     : abap.char(40);
  sap_user     : syuname;
  log_date     : abap.dats;
  log_time     : abap.tims;
  source       : abap.char(4);
  note         : abap.char(80);
}
