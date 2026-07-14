@EndUserText.label: 'repackItems - import'
define abstract entity ZD_REPACK
{
  SourceHandlingUnit : abap.char(20);
  TargetHandlingUnit : abap.char(20);
  _Item : composition [0..*] of ZD_REPACK_ITEM;
}
