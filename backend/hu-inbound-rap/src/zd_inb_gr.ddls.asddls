@EndUserText.label: 'postInboundGr - import'
define abstract entity ZD_InbGr
{
  InboundDelivery : abap.char(10);
  _Item : composition [0..*] of ZD_InbGrHu;
}
