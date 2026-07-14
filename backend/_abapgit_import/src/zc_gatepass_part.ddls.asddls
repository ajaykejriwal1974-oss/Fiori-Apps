@EndUserText.label: 'Gate Pass - Projection (inward receipt part)'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
define view entity ZC_GATEPASS_PART
  as projection on ZI_GATEPASS_PART
{
  key GpNumber,
  key ItemNumber,
  key PartCount,
      ReceivedQuantity,
      BillingDocument,
      BillingDate,
      MaterialStatus
}
