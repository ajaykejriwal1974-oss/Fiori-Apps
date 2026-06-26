@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Digital Signature Master - Interface'
@Metadata.allowExtensions: true
// Custom master (Route 7) - managed RAP over legacy table ZTDIGI_SIGN (ZDIGI).
// Field list mirrors the real Z-table (field dictionary). This legacy table
// has no TIMESTAMPL column, so the optimistic-concurrency ETag is omitted
// (add a TIMESTAMPL column to enable it).
define root view entity ZI_DigitalSignature
  as select from ztdigi_sign
{
  key bukrs                  as CompanyCode,
      email                  as Email,
      pwd                    as Password,
      ip                     as IpAddress,
      pfx                    as PfxPrefix,
      source_folder          as SourceFolder,
      dest_folder            as DestinationFolder
}
