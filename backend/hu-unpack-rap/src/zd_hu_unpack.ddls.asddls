@EndUserText.label: 'unpackItems - import'
define abstract entity ZD_HuUnpack
{
  TargetStorageLocation : abap.char(4);
  _Item : composition [0..*] of ZD_HuUnpackItem;
}
