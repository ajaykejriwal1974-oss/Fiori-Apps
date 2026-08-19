@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Label Master - Interface'
@Metadata.allowExtensions: true
@ObjectModel.semanticKey: ['Plant', 'Brand', 'LabelNumber']
//
// ============================ VERIFY BEFORE ACTIVATION ======================
// This is the ONLY object in the Label Master app whose field list could not be
// read from the live system (ADT was unreachable when it was written). Every
// name in the SELECT list below comes from the naming convention of the sibling
// tables ZPP_PACK and ZPP_BATCHN, not from ZPP_LABEL itself.
//
// To finish: SE11 -> ZPP_LABEL -> Fields, and correct the left-hand column
// below. Nothing else in the app needs to change - the projection, behaviour
// definition, behaviour pool, service and UI5 view all address the ALIASES on
// the right-hand side, which are stable.
//
// What the legacy screen (ZLABEL, "Maintain Label Master") shows:
//   group box  : Dyeing ( 2002 )        -> Plant
//   radio group: Kejriwal / Karishma /
//                Microtex / Blank       -> Brand
// so Plant + Brand are certainly keys. LabelNumber is the per-brand line key.
// ===========================================================================
//
define root view entity ZI_LABEL_MASTER
  as select from zpp_label as lbl
    left outer join t001k as vcc on vcc.bwkey = lbl.werks
{
  key lbl.werks     as Plant,
  key lbl.brand     as Brand,
  key lbl.labelno   as LabelNumber,
      vcc.bukrs     as CompanyCode,
      lbl.matnr     as Material,
      lbl.grade     as Grade,
      lbl.shade     as Shade,
      lbl.ptype     as PackingType,
      lbl.labeltext as LabelText,
      lbl.active    as IsActive,
      lbl.erdat     as CreatedOn,
      lbl.ernam     as CreatedBy,
      lbl.aedat     as ChangedOn,
      lbl.aenam     as ChangedBy
}
