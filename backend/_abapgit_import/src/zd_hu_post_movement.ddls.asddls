@EndUserText.label: 'Post HU Goods Movement - action import'
// Flat action parameter. HandlingUnitList carries the HU numbers as
// 'HU1;HU2;HU3' - the HU contents (material/batch/qty) are read from VEPO
// on the server, so no item detail travels over the wire.
define abstract entity ZD_HU_POST_MOVEMENT
{
  MovementType             : abap.char(3);
  Plant                    : abap.char(4);
  StorageLocation          : abap.char(4);
  ReceivingStorageLocation : abap.char(4);
  HandlingUnitList         : abap.char(1333);
}
