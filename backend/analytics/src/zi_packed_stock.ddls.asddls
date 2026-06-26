@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Packed-Stock Analysis - Cube'
@Analytics: { dataCategory: #CUBE, dataExtraction.enabled: true }
@Metadata.allowExtensions: true
// Analytical cube over ZPP_PACK. Replaces: ZBOXSTOCK, ZGSTOCK, ZPRP1, ZSSTOCK, ZDSTOCK, ZSTOCK, ZPRP, ZPRPSZ.
// Old report variants are now dimensions; aggregate in the query.
define view entity ZI_PackedStockCube
  as select from zpp_pack
{
  key boxno            as Box,
  key gjahr            as FiscalYear,
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
      @DefaultAggregation: #SUM
      grosswt          as GrossWeight,
      @DefaultAggregation: #SUM
      tarewt           as TareWeight,
      @DefaultAggregation: #SUM
      netwt            as NetWeight,
      @DefaultAggregation: #SUM
      @EndUserText.label: 'Record Count'
      cast( 1 as abap.int4 ) as RecordCount
}
