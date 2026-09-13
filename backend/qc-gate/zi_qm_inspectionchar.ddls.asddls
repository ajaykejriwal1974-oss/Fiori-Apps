@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'QM Open Inspection Characteristics - Interface'
@Metadata.allowExtensions: true
@ObjectModel.semanticKey: ['InspectionLot', 'InspectionOperation', 'InspectionCharacteristic']
//
//  Read model for mass / multi-lot inspection result entry (replaces ZQA32,
//  legacy program ZQM_MASS_RESULT2). Sourced from the standard QM dictionary;
//  results are NOT persisted here - they are recorded through the QM
//  result-recording API in the behavior save.
//
//  "Open" (2026-09-05, QC audit) means two things, both checked in KSD:
//    - the lot has no usage decision yet (QALS-STAT35 blank). Once the
//      decision is made the lot takes no further results; before this filter
//      the app listed every characteristic of every lot ever created.
//    - the characteristic's result record is not closed (QAMR-SATZSTATUS
//      '5'). QAMR holds one row per characteristic for summarised recording
//      (key = QAMV key), so the join cannot multiply rows; a characteristic
//      with no result row yet has no QAMR row at all and stays in.
//
define root view entity ZI_QM_INSPECTIONCHAR
  as select from qamv as char
    inner join      qals as lot on lot.prueflos = char.prueflos
    left outer join qamr as res on  res.prueflos = char.prueflos
                                and res.vorglfnr = char.vorglfnr
                                and res.merknr   = char.merknr
{
  key char.prueflos                                       as InspectionLot,
  key char.vorglfnr                                       as InspectionOperation,
  key char.merknr                                         as InspectionCharacteristic,
      char.kurztext                                       as CharacteristicDescription,
      lot.matnr                                           as Material,
      lot.werk                                            as Plant,
      char.masseinhsw                                     as Unit,
      fltp_to_dec( res.mittelwert as abap.dec( 16, 3 ) )  as ResultValue,
      res.mbewertg                                        as Valuation,
      lot.art                                             as InspectionType,
      lot.herkunft                                        as Origin
}
where
      lot.stat35     = ''
  and (
       res.satzstatus is null
    or res.satzstatus <> '5'
  )
