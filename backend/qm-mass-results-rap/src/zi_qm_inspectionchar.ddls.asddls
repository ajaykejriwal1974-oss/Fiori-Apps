@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'QM Open Inspection Characteristics - Interface'
@Metadata.allowExtensions: true
@ObjectModel.semanticKey: ['InspectionLot', 'InspectionOperation', 'InspectionCharacteristic']
//
//  Read model for mass / multi-lot inspection result entry (replaces ZQA32).
//  Sourced from the standard QM dictionary; results are NOT persisted here -
//  they are recorded through the QM result-recording API in the behavior save.
//
//  VERIFY against your release before activating: QM table/field names
//  (qamv/qals/qapo/qamr), the "open characteristic" status filter, and the
//  work-center derivation. Prefer released QM CDS interfaces where available.
//
define root view entity ZI_QM_InspectionChar
  as select from qamv as char
    inner join      qals as lot  on  lot.prueflos  = char.prueflos
    left outer join qapo as oper on  oper.prueflos = char.prueflos
                                 and oper.vorglfnr = char.vorglfnr
  association [0..1] to qamr         as _Result
    on  _Result.prueflos = char.prueflos
    and _Result.vorglfnr = char.vorglfnr
    and _Result.merknr   = char.merknr
  association [0..1] to I_WorkCenter as _WorkCenter
    on _WorkCenter.WorkCenterInternalID = oper.arbid
{
  key char.prueflos                                  as InspectionLot,
  key char.vorglfnr                                  as InspectionOperation,
  key char.merknr                                    as InspectionCharacteristic,
      char.kurztext                                  as CharacteristicDescription,
      lot.matnr                                      as Material,
      lot.werk                                       as Plant,
      _WorkCenter.WorkCenter                         as WorkCenter,
      char.maeinheit                                 as Unit,
      cast( _Result.mittelwert as abap.dec( 16, 3 ) ) as ResultValue,
      _Result.mbewertg                               as Valuation,
      lot.art                                        as InspectionType,
      lot.herkunft                                   as Origin
}
//  Open characteristics only (lot released / inspection in process).
//  Replace 'stat34' with the correct status flag for your release.
where lot.stat34 = 'X'
