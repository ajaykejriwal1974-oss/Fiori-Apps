@EndUserText.label: 'postPackingAndGr - import item'
define abstract entity ZD_POST_PACK_GR_ITEM
{
  HandlingUnit : abap.char(20);
  _Parent : association to parent ZD_POST_PACK_GR;
}
