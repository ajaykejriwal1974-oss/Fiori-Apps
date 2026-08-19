@EndUserText.label: 'cancelConfirmations - import'
// Flat action parameter. ConfirmationList carries confirmation=counter pairs
// as '0000012345=1;0000012345=2;0000012346=1'. A blank PostingDate lets the
// server default to today.
define abstract entity ZD_CONF_CANCEL
{
  PostingDate      : abap.dats;
  ConfirmationList : abap.char(1333);
}
