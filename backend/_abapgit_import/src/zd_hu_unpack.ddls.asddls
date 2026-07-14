@EndUserText.label: 'unpackItems - import'
define abstract entity ZD_HU_UNPACK
{
  TargetStorageLocation : abap.char(4);
  _Item : composition [0..*] of ZD_HU_UNPACK_ITEM;
}
