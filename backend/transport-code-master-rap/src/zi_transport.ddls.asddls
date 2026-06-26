@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Transport Code Master - Interface'
@Metadata.allowExtensions: true
// Custom master (Route 7) - managed RAP over legacy table ZTRANS (ZTRANS).
// Field list mirrors the real Z-table (field dictionary). This legacy table
// has no TIMESTAMPL column, so the optimistic-concurrency ETag is omitted
// (add a TIMESTAMPL column to enable it). Code fields carry in-table text
// (@ObjectModel.text.element) and value helps (on the projection).
define root view entity ZI_Transport
  as select from ztrans
{
  key zztrcode               as TransportCode,
  key zztrckno               as TruckNumber,
      zztrdesc               as Description
}
