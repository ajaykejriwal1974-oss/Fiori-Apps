@EndUserText.label: 'QC Char + derived Stage (Scan Suite)'
@AccessControl.authorizationCheck: #CHECK
define view entity ZC_QC_INSP_CHAR_SCAN
  as select from ZC_QC_INSP_CHAR
{
  key InspectionLot,
  key OperationNumber,
  key CharacteristicNumber,
      MasterCharacteristic,
      CharacteristicName,
      CharacteristicKind,
      CharacteristicUnit,
      DecimalPlaces,
      TargetValue,
      TargetIsInitial,
      LowerLimit,
      LowerLimitIsInitial,
      UpperLimit,
      UpperLimitIsInitial,
      SelectedSet,
      CatalogType,
      MeanValue,
      MeanIsInitial,
      ResultCode,
      ResultCodeGroup,
      DefectCount,
      ActualSampleSize,
      Valuation,
      InspectorComment,
      ResultStatus,

      // ---- derived Stage: colour panel = 'D' (dyeing), physical = 'W' (winding) ----
      // This replaces the ABAP CASE in ZCL_ZSOL_QC_SCAN.LIST_CHARS. One declarative
      // place for the MIC -> stage mapping. (See review pack for the mapping-table
      // variant that removes the need to touch code when a new MIC is added.)
      cast(
        case upper( MasterCharacteristic )
          when 'CDELTA'   then 'D'
          when 'WASHFAS'  then 'D'
          when 'LIGHTFAS' then 'D'
          when 'RUBDRY'   then 'D'
          when 'RUBWET'   then 'D'
          when 'DENIER'   then 'W'
          when 'FILAMENT' then 'W'
          when 'TENACITY' then 'W'
          when 'NIPS'     then 'W'
          when 'ELONGATN' then 'W'
          when 'OIL'      then 'W'
          when 'PKGHAR'   then 'W'
          when 'MOUST'    then 'W'
          when 'PKGWT'    then 'W'
          when 'LENGTH'   then 'W'
          when 'PKG_DEN'  then 'W'
          when 'MOISTURE' then 'W'
          when 'PKG_LEN'  then 'W'
          when 'PKG_WT'   then 'W'
          when 'PKG_BILD' then 'W'
          else ' '
        end as abap.char( 1 ) ) as Stage
}
