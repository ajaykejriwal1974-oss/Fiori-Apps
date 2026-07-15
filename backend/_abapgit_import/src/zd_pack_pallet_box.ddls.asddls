@EndUserText.label: 'packPallet - import item'
define abstract entity ZD_PACK_PALLET_BOX
{
  HandlingUnit : abap.char(20);
  _Parent : association to parent ZD_PACK_PALLET;
}
