@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Print Label Master - Interface'
@Metadata.allowExtensions: true
@ObjectModel.semanticKey: ['Plant', 'LabelType', 'IPAddress']
// ZPP_LABEL is the PRINT label master (legacy tx ZLABEL, SAPMZ_PP_LABEL_001):
// which label printer (IP address) serves which label type at which plant, and
// which of them is the default. The legacy screen's radio group
// (Kejriwal / Karishma / Microtex / Blank) is the TYPE column.
// Key is Plant + LabelType + IPAddress - all three are user-entered, so there
// is no managed numbering.
define root view entity ZI_LABEL_MASTER
  as select from zpp_label as lbl
{
  key lbl.werks as Plant,
  key lbl.type  as LabelType,
  key lbl.ip    as IPAddress,
      lbl.text  as LabelText,
      lbl.dflt  as IsDefault
}
