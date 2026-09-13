@EndUserText.label : 'QC-driven confirmation to plant batch'
@AbapCatalog.enhancement.category : #NOT_EXTENSIBLE
@AbapCatalog.tableCategory : #TRANSPARENT
@AbapCatalog.deliveryClass : #A
@AbapCatalog.dataMaintenance : #RESTRICTED
// AFRU ties a confirmation to an order and an operation and nothing else -
// there is no batch column anywhere in it. So a confirmation for 1200 KG on
// order 000001008691 operation 0020 cannot be told apart from any other, and
// the plant batch that actually passed inspection is lost the moment it is
// posted.
//
// This table is the missing edge. One row per confirmation, keyed on the
// confirmation's own key so it can never disagree with AFRU, carrying the
// batch, the job card and the inspection lot whose usage decision released it.
// Written only by the QC apps; a confirmation posted through ZCO11A leaves no
// row here, which is itself informative - it says the confirmation did not go
// through quality control.
define table zqc_conf_batch {

  key mandt      : mandt not null;
  // AFRU-RUECK and AFRU-RMZHL. The full key of the confirmation record, so a
  // cancelled or reversed confirmation is found by the same key.
  key rueck      : co_rueck not null;
  key rmzhl      : co_rmzhl not null;

  aufnr          : aufnr;
  vornr          : vornr;
  werks          : werks_d;

  // The plant batch that was inspected. CHARG_D because that is what
  // ZPP_BATCHN-BATCHNO is typed as.
  batchno        : charg_d;
  gjahr          : gjahr;
  jobno          : zde_jobno;

  // The lot whose usage decision authorised this confirmation, and the
  // valuation that decision carried. Copied rather than joined: a lot can be
  // re-decided later, and this has to record what was true at the moment the
  // confirmation was posted.
  prueflos       : qplos;
  ud_code        : qvcode;
  ud_codegrp     : qvgruppe;
  ud_valuation   : qbewertung;

  lmnga          : ru_lmnga;
  xmnga          : ru_xmnga;
  meinh          : ru_vorme;
  budat          : buchdatum;

  ernam          : ernam;
  erdat          : erdat;
  erzet          : erzeit;

}
