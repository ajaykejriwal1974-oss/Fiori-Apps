@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Gate Pass - Interface (inward receipt part)'
@Metadata.allowExtensions: true
// Inward-receipt detail over ZGP_PART (used by the inward flow ZGPSI1/2/3).
// NOTE: ZGP_PART has keys GPNUM + ZITEM + CNT but NO MJAHR - so it is a plain
// associated entity here, not a composition child. Add MJAHR to ZGP_PART (or a
// surrogate) to fold it into the gate-pass composition tree.
define view entity ZI_GatePassPart
  as select from zgp_part
{
  key gpnum                  as GpNumber,
  key zitem                  as ItemNumber,
  key cnt                    as PartCount,
      rec_quan               as ReceivedQuantity,
      vbill_no               as BillingDocument,
      vbill_dt               as BillingDate,
      mat_stat               as MaterialStatus
}
