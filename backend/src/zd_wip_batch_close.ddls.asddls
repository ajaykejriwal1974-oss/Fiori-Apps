@EndUserText.label: 'closeBatches / reopenBatches - import'
// Flat action parameter for the WIP Batch Close app. BatchList carries
// batch=fiscalYear pairs as '2120015369=2026;2120015370=2026'.
// Reason is free text stored with the change so a reopen can be justified.
// NOTE: distinct from ZD_BATCH_CLOSE, which belongs to ZI_BATCH_STATUS and
// works on the material batch master (MCHA), not the dyeing WIP batch.
define abstract entity ZD_WIP_BATCH_CLOSE
{
  Reason    : abap.char(80);
  BatchList : abap.char(1333);
}
