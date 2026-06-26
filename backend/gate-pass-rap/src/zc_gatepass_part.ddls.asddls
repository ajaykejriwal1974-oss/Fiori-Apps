@EndUserText.label: 'Gate Pass - Projection (inward receipt part)'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
define view entity ZC_GatePassPart
  as projection on ZI_GatePassPart
{
  key GpNumber,
  key ItemNumber,
  key PartCount,
      ReceivedQuantity,
      BillingDocument,
      BillingDate,
      MaterialStatus
}
