@EndUserText.label : 'Knitting roll QC - one row per roll (Mango Filament)'
@AbapCatalog.enhancement.category : #NOT_EXTENSIBLE
@AbapCatalog.tableCategory : #TRANSPARENT
@AbapCatalog.deliveryClass : #A
@AbapCatalog.dataMaintenance : #RESTRICTED
define table zknit_roll_qc {

  key mandt          : mandt not null;
  key werks          : werks_d not null;
  key arbpl          : arbpl not null;
  key mrno           : abap.numc(6) not null;

  zmrno              : zdemrno;
  aufnr              : aufnr;
  matnr              : matnr;
  print_date         : abap.dats;

  pqc_date           : abap.dats;
  pqc_time           : abap.tims;
  pqc_user           : abap.char(40);
  pqc_grade          : zde_gcode;
  pqc_defects        : abap.char(60);
  pqc_remark         : abap.char(100);

  dqc_status         : abap.char(1);
  dqc_sent_date      : abap.dats;
  dqc_sent_time      : abap.tims;
  dqc_sent_user      : abap.char(40);
  dqc_recv_date      : abap.dats;
  dqc_recv_time      : abap.tims;
  dqc_recv_user      : abap.char(40);
  dqc_res_date       : abap.dats;
  dqc_res_time       : abap.tims;
  dqc_res_user       : abap.char(40);
  dqc_remark         : abap.char(100);

  ernam              : abap.char(40);
  erdat              : abap.dats;
  erzet              : abap.tims;
  aenam              : abap.char(40);
  aedat              : abap.dats;
  aezet              : abap.tims;

}
