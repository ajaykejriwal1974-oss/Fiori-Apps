@EndUserText.label: 'convertToMts - import'
//  Composition parameter (was flat): all selected stock lines convert in ONE
//  BAPI_GOODSMVT_CREATE call - one 411-E material document, one commit - instead
//  of one HTTP round trip + BAPI + COMMIT WORK per selected row.
define abstract entity ZD_MtoMts
{
  _Item : composition [0..*] of ZD_MtoMtsItem;
}
