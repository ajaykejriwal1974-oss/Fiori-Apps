@EndUserText.label: 'Post HU Goods Movement - action import (item)'
define abstract entity ZD_HU_POST_MVT_ITEM
{
  HandlingUnit : abap.char(20);
  Material     : abap.char(40);
  Batch        : abap.char(10);
  Quantity     : abap.dec(13,3);
  Unit         : abap.unit(3);
}
