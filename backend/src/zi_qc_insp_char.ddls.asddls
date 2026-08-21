@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'QC Characteristic - Interface'
@Metadata.allowExtensions: true
// One row per characteristic of an inspection lot operation, with its
// specification from QAMV and its summarised result from QAMR.
//
// NO parent association, and the lot reaches this by a plain association
// rather than a composition. Composition plus association-to-parent is the
// textbook RAP pattern, but it is a hard activation cycle: the parent will not
// activate until the child's ACTIVE version already carries the to-parent
// association, and the child cannot carry it until the parent exists. Four
// joint-activation attempts in KSD failed. Results are written by an action on
// the lot instead - see ZI_QC_INSP_LOT.
//
// Keys verified: QAMV and QAMR share PRUEFLOS + VORGLFNR + MERKNR, so the
// join cannot fan out.
//
// The *NI fields are not noise. SOLLWERT, TOLERANZOB and TOLERANZUN are FLTP,
// which cannot distinguish "zero" from "not maintained". SAP therefore carries
// a companion flag - SOLLWNI, TOLOBNI, TOLUNNI - set when the value is
// initial. The UI must read the flag before it renders a limit, or every
// unmaintained limit displays as 0.00 and every result looks out of tolerance.
define view entity ZI_QC_INSP_CHAR
  as select from qamv as spec
    left outer join qamr as res on  res.prueflos = spec.prueflos
                               and  res.vorglfnr = spec.vorglfnr
                               and  res.merknr   = spec.merknr
{
  key spec.prueflos                               as InspectionLot,
  key spec.vorglfnr                               as OperationNumber,
  key spec.merknr                                 as CharacteristicNumber,
      spec.verwmerkm                              as MasterCharacteristic,
      spec.kurztext                               as CharacteristicName,
      spec.steuerkz                               as ControlIndicators,
      spec.stellen                                as DecimalPlaces,
      spec.masseinhsw                             as CharacteristicUnit,
      // Specification - FLTP, each with its is-initial companion flag
      spec.sollwert                               as TargetValue,
      spec.sollwni                                as TargetIsInitial,
      spec.toleranzun                             as LowerLimit,
      spec.tolunni                                as LowerLimitIsInitial,
      spec.toleranzob                             as UpperLimit,
      spec.tolobni                                as UpperLimitIsInitial,
      // Qualitative characteristics carry a catalog and selected set
      spec.katalgart1                             as CatalogType,
      spec.auswmenge1                             as SelectedSet,
      // Recorded result
      res.mittelwert                              as MeanValue,
      res.mittelwni                               as MeanIsInitial,
      res.gruppe1                                 as ResultCodeGroup,
      res.code1                                   as ResultCode,
      res.anzfehler                               as DefectCount,
      res.iststpumf                               as ActualSampleSize,
      res.mbewertg                                as Valuation,
      res.pruefer                                 as Inspector,
      res.pruefdatub                              as InspectionDate,
      res.pruefbemkt                              as InspectorComment,
      res.satzstatus                              as ResultStatus,
      // Quantitative when a unit or decimals are set, qualitative otherwise
      case when spec.katalgart1 <> '' then cast('QUAL' as abap.char(4))
                                      else cast('QUAN' as abap.char(4))
      end                                         as CharacteristicKind
}
