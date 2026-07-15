@EndUserText.label: 'postPackingAndGr - import'
// Flat action parameter. HandlingUnitList carries the HU numbers as
// 'HU1;HU2;HU3' - HU contents are read from VEPO on the server.
define abstract entity ZD_POST_PACK_GR
{
  MovementType     : abap.char(3);
  Plant            : abap.char(4);
  StorageLocation  : abap.char(4);
  HandlingUnitList : abap.char(1333);
}
