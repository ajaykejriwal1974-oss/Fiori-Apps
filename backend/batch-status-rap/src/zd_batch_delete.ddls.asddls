@EndUserText.label: 'deleteBatch - import'
//  Composition parameter (was flat) - see ZD_BatchClose.
define abstract entity ZD_BatchDelete
{
  _Item : composition [0..*] of ZD_BatchDeleteItem;
}
