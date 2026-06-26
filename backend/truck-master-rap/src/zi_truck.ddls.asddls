@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Truck Master - Interface'
@Metadata.allowExtensions: true
// Custom master (Route 7) - managed RAP over legacy table ZTB_TRUCK_MSTR (ZTRUCK).
// Field list mirrors the real Z-table (field dictionary). This legacy table
// has no TIMESTAMPL column, so the optimistic-concurrency ETag is omitted
// (add a TIMESTAMPL column to enable it).
define root view entity ZI_Truck
  as select from ztb_truck_mstr
{
  key truckno                as TruckNumber,
      carrier_name           as CarrierName
}
