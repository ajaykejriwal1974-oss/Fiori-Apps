@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Packed Stock / Packing (ZPP_PACK) - Cube'
@Analytics: { dataCategory: #CUBE, dataExtraction.enabled: true }
@Metadata.allowExtensions: true
// Single analytical cube over ZPP_PACK feeding BOTH the packed-stock analysis and
// the packing/dispatch register queries (audit P4 - one cube, many queries).
// Replaces the stock reports (ZBOXSTOCK, ZGSTOCK, ZPRP1, ZSSTOCK, ZDSTOCK, ZSTOCK,
// ZPRP, ZPRPSZ) AND the packing-list family (ZPLIST01..03(+A/T/N/D), ZPACKLIST*).
// Old report variants are now dimensions; aggregate in the query.
define view entity ZI_PACKED_STOCK
  as select from zpp_pack
{
  key boxno            as Box,
  key gjahr            as FiscalYear,
      // stock dimensions
      werks            as Plant,
      lgort            as StorageLocation,
      matnr            as Material,
      grade            as Grade,
      enduse           as EndUse,
      ptype            as PackingType,
      psize            as Size,
      mergno           as MergeNumber,
      arbpl            as WorkCenter,
      pltyp            as ProductType,
      pdate            as PackingDate,
      // packing / dispatch register dimensions
      vbeln            as SalesDocument,
      posnr            as SalesItem,
      aufnr            as ProductionOrder,
      plist            as PackingListFlag,
      posted           as Posted,
      pldate           as PackingListDate,
      // measures
      @DefaultAggregation: #SUM
      cast( grosswt as abap.dec( 15, 3 ) ) as GrossWeight,
      @DefaultAggregation: #SUM
      cast( tarewt as abap.dec( 15, 3 ) ) as TareWeight,
      @DefaultAggregation: #SUM
      cast( netwt as abap.dec( 15, 3 ) ) as NetWeight,
      @DefaultAggregation: #SUM
      @EndUserText.label: 'Record Count'
      cast( 1 as abap.int4 ) as RecordCount
}
