*** REPLACE FROM "define behavior for" TO THE FINAL "}" ONLY. ***
*** Leave everything above it - the header comments, the
*** "unmanaged implementation in class zbp_i_qc_insp_lot unique;" line and
*** "strict ( 2 );" - exactly as it is. I cannot see those lines.

define behavior for ZI_QC_INSP_LOT alias InspectionLot
lock master
authorization master ( global )
{
  // Instance feature control. The Detail screen binds each footer button to
  // __OperationControl/<action>, and that property only reaches the OData
  // service when the action declares ( features : instance ). Without it the
  // binding resolves to undefined, UI5 reads it as false, and every button is
  // disabled on every lot - which is why Save, Record Results and Usage
  // Decision have never been pressable.
  //
  // Implemented in get_instance_features: STAT34 (results confirmed) switches
  // off both record actions, STAT35 (usage decision made) switches off the
  // decision.

  // One result for one characteristic. Called once per changed row.
  action ( features : instance ) recordSingleResult parameter ZD_QC_SINGLE_RESULT result [1] $self;

  // Confirm the operation - no more results accepted afterwards.
  action ( features : instance ) recordResults      parameter ZD_QC_RECORD_RESULTS result [1] $self;

  // Close the lot with a usage decision.
  action ( features : instance ) setUsageDecision   parameter ZD_QC_USAGE_DECISION result [1] $self;

  // ---- added 2026-08-28: passing QC performs the next physical step -------
  //
  // Each of these is a SECOND round trip, not part of Save. The usage decision
  // moves stock out of inspection in its own update task; a transfer posted in
  // that same LUW would read stock that has not moved yet and fail on a
  // deficit. Feature control disables them until the decision is on the
  // database, and the saver re-checks - feature control shapes a button and
  // has never enforced anything.

  // Grey QC follow-on: movement 301 from DRM1 to DPR1, the transfer that
  // actually puts yarn on the dyeing floor. Order consumption happens at
  // packing, far too late to be a control point. Carries a receiving batch:
  // the supplier batch in DRM1 becomes the production greige lot in DPR1,
  // which is what ZPP_BATCHN-LOTNO holds.
  action ( features : instance ) releaseToProduction
    parameter ZD_QC_RELEASE_PROD result [1] $self;

  // Post-Dyeing follow-on: operation 0010, work centres DYG00001 / DYG00012.
  // Posts through BAPI_PRODORDCONF_CREATE_TT - the same BAPI ZCO11A calls,
  // minus the commit, which the RAP framework owns.
  action ( features : instance ) confirmDyeing
    parameter ZD_QC_CONFIRM_PROD result [1] $self;

  // Post-Winding follow-on: operation 0020, work centre WIN00025, and the
  // point after which packing may proceed.
  action ( features : instance ) confirmWinding
    parameter ZD_QC_CONFIRM_PROD result [1] $self;
}
