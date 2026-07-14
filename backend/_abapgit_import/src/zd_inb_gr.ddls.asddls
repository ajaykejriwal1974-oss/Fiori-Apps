@EndUserText.label: 'postInboundGr - import'
define abstract entity ZD_INB_GR
{
  InboundDelivery : abap.char(10);
  _Item : composition [0..*] of ZD_INB_GR_HU;
}
