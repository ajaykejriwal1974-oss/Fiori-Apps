@EndUserText.label: 'postInboundGr - import item'
define abstract entity ZD_INB_GR_HU
{
  HandlingUnit : abap.char(20);
  _Parent : association to parent ZD_INB_GR;
}
