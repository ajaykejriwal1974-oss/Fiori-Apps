@EndUserText.label: 'Create Packing HUs - action import (unit)'
define abstract entity ZD_PACK_CREATE_UNIT
{
  LevelType       : abap.char(10);   //  Cone / Carton / Pallet
  PackingMaterial : abap.char(40);
  Quantity        : abap.dec(13,3);
  NetWeight       : abap.dec(15,3);
  GrossWeight     : abap.dec(15,3);
  _Parent : association to parent ZD_PACK_CREATE;
}
