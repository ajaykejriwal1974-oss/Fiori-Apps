@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Packing Material Master - Interface'
@Metadata.allowExtensions: true
// Custom master (Route 7) - managed RAP over legacy table ZPACK_MAST (ZPACK_MAST).
// Field list mirrors the real Z-table (field dictionary). This legacy table
// has no TIMESTAMPL column, so the optimistic-concurrency ETag is omitted
// (add a TIMESTAMPL column to enable it).
define root view entity ZI_PackingMaterial
  as select from zpack_mast
{
  key ptype                  as PackingType,
  key arbpl                  as WorkCenter,
  key matnr                  as Material,
      lgort                  as StorageLocation,
      charg                  as Batch,
      seq                    as Sequence
}
