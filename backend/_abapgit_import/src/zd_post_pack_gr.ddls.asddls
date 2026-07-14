@EndUserText.label: 'postPackingAndGr - import'
define abstract entity ZD_POST_PACK_GR
{
  MovementType : abap.char(3);
  Plant : abap.char(4);
  StorageLocation : abap.char(4);
  _Item : composition [0..*] of ZD_POST_PACK_GR_ITEM;
}
