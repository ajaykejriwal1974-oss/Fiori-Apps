@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Checked / Packed By Master - Interface'
@Metadata.allowExtensions: true
// Custom master (Route 7) - managed RAP over legacy table ZPP_PCBY (ZPCBY).
// Field list mirrors the real Z-table (field dictionary). This legacy table
// has no TIMESTAMPL column, so the optimistic-concurrency ETag is omitted
// (add a TIMESTAMPL column to enable it).
define root view entity ZI_CheckedBy
  as select from zpp_pcby
{
  key sr_no                  as SerialNumber,
  key pc                     as CheckedPackedFlag,
      usr_name               as UserName
}
