@EndUserText.label: 'unpackItems - import'
// Flat action parameter. HuItemList carries HU=item pairs as
// 'HU1=0001;HU1=0002;HU2=0001' - item detail is read from VEPO on the server.
define abstract entity ZD_HU_UNPACK
{
  TargetStorageLocation : abap.char(4);
  HuItemList            : abap.char(1333);
}
