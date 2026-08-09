@EndUserText.label: 'Create Packing HUs - action import (unit)'
define abstract entity ZD_Pack_Create_Unit
{
  LevelType       : abap.char(10);   //  Cone / Carton / Pallet
  PackingMaterial : abap.char(40);
  Quantity        : abap.quan(13,3);
  NetWeight       : abap.quan(15,3);
  GrossWeight     : abap.quan(15,3);
}
