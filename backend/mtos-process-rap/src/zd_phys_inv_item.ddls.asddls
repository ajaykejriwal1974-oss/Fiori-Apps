@EndUserText.label: 'createPhysInvDoc - import item'
define abstract entity ZD_PhysInvItem
{
  Material : abap.char(40);
  Batch : abap.char(10);
  HandlingUnit : abap.char(20);
}
