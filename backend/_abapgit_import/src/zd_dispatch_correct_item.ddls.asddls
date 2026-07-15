@EndUserText.label: 'Correct Dispatch - item (box)'
define abstract entity ZD_DISPATCH_CORRECT_ITEM
{
  BoxNumber : abap.char(10);
  _Parent : association to parent ZD_DISPATCH_CORRECT;
}
