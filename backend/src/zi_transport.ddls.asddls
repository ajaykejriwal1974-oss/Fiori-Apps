@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Transport Code Master - Interface'
@Metadata.allowExtensions: true
// Managed RAP over base table ZTRCKMSTR (the ZTRANS view's primary table).
// The description ZZTRDESC lives in the separate table ZTRPTMSTR and is omitted
// from this editable BO (add it later via a read-only association to ZTRPTMSTR).
define root view entity ZI_TRANSPORT
  as select from ztrckmstr
{
  key zztrcode               as TransportCode,
  key zztrckno               as TruckNumber
}
