@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Packing / Dispatch Register - Cube'
@Analytics: { dataCategory: #CUBE, dataExtraction.enabled: true }
@Metadata.allowExtensions: true
// Analytical cube over ZPP_PACK. Replaces: ZPLIST01..03(+A/T/N/D), ZPACKLIST, ZPACKLIST01, ZPACKLISTN, ZPACKLIST(report).
// Old report variants are now dimensions; aggregate in the query.
define view entity ZI_PackingRegisterCube
  as select from zpp_pack
{
  key boxno            as Box,
  key gjahr            as FiscalYear,
      vbeln            as SalesDocument,
      posnr            as SalesItem,
      aufnr            as Order,
      matnr            as Material,
      grade            as Grade,
      ptype            as PackingType,
      plist            as PackingListFlag,
      posted           as Posted,
      pldate           as PackingListDate,
      @DefaultAggregation: #SUM
      netwt            as NetWeight,
      @DefaultAggregation: #SUM
      grosswt          as GrossWeight,
      @DefaultAggregation: #SUM
      @EndUserText.label: 'Record Count'
      cast( 1 as abap.int4 ) as RecordCount
}
