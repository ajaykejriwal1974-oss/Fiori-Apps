@EndUserText.label: 'createPhysInvDoc - import'
define abstract entity ZD_PhysInv
{
  Plant : abap.char(4);
  StorageLocation : abap.char(4);
  FiscalYear : abap.numc(4);
  _Item : composition [0..*] of ZD_PhysInvItem;
}
