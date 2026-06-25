@EndUserText.label: 'Post HU Goods Movement - action import (header)'
define abstract entity ZD_HU_PostMovement
{
  MovementType             : abap.char(3);
  Plant                    : abap.char(4);
  StorageLocation          : abap.char(4);
  ReceivingStorageLocation : abap.char(4);
  _Item : composition [0..*] of ZD_HU_PostMvtItem;
}
