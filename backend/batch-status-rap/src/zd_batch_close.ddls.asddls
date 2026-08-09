@EndUserText.label: 'closeBatch - import'
//  Composition parameter (was flat Material/Plant/Batch): the worklist's mass action
//  now sends ALL selected batches in ONE call with ONE commit, instead of one HTTP
//  round trip + one synchronous COMMIT WORK per selected row.
define abstract entity ZD_BatchClose
{
  _Item : composition [0..*] of ZD_BatchCloseItem;
}
