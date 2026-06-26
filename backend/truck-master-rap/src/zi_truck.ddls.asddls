@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Truck Master - Interface'
@Metadata.allowExtensions: true
@ObjectModel.semanticKey: ['TruckNumber']
// Custom master (Route 7) - managed RAP, same pattern as ZDD_SHADE.
// VERIFY the field list against the original Z program before activating.
define root view entity ZI_Truck
  as select from ztruck
{
  key truck_number               as TruckNumber,
      transporter_name           as TransporterName,
      transport_code             as TransportCode,
      driver_name                as DriverName,
      capacity_kg                as CapacityInKg,
      is_active                  as IsActive,
      @Semantics.user.createdBy: true
      created_by                 as CreatedBy,
      @Semantics.systemDateTime.createdAt: true
      created_at                 as CreatedAt,
      @Semantics.user.lastChangedBy: true
      last_changed_by            as LastChangedBy,
      @Semantics.systemDateTime.lastChangedAt: true
      last_changed_at            as LastChangedAt,
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      local_last_changed_at      as LocalLastChangedAt
}
