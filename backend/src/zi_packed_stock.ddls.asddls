@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Packed Stock / Packing (ZPP_PACK) - Cube'
@Analytics: { dataCategory: #CUBE, dataExtraction.enabled: true }
@Metadata.allowExtensions: true
// Single analytical cube over ZPP_PACK feeding BOTH the packed-stock analysis and
// the packing/dispatch register queries (audit P4 - one cube, many queries).
// Replaces the stock reports (ZBOXSTOCK, ZGSTOCK, ZPRP1, ZSSTOCK, ZDSTOCK, ZSTOCK,
// ZPRP, ZPRPSZ) AND the packing-list family (ZPLIST01..03(+A/T/N/D), ZPACKLIST*).
// Old report variants are now dimensions; aggregate in the query.
// ZZMARA is the Kejriwal material extension: it carries the textile attributes
// the dispatch desk selects on in ZBOXSTOCK - product type, denier, filament.
// ZPP_PACK already carries ProductType (pltyp); Denier and Filament exist only
// on the material, so they are joined in here. Left outer join: a box whose
// material has no ZZMARA row still appears, with blank denier/filament.
define view entity ZI_PACKED_STOCK
  as select from zpp_pack as pck
    left outer join zzmara as ext on ext.matnr = pck.matnr
{
  key pck.boxno        as Box,
  key pck.gjahr        as FiscalYear,
      // stock dimensions
      pck.werks            as Plant,
      pck.lgort            as StorageLocation,
      pck.matnr            as Material,
      pck.grade            as Grade,
      pck.enduse           as EndUse,
      pck.ptype            as PackingType,
      pck.psize            as PackingSize,
      pck.mergno           as MergeNumber,
      pck.arbpl            as WorkCenter,
      pck.pltyp            as ProductType,
      // ZBOXSTOCK selection fields sourced from the material extension
      ext.zzdenir      as Denier,
      ext.zzfilam      as Filament,
      ext.zzpdtyp      as MaterialProductType,
      pck.pdate            as PackingDate,
      // packing / dispatch register dimensions
      pck.vbeln            as SalesDocument,
      pck.posnr            as SalesItem,
      pck.aufnr            as ProductionOrder,
      pck.plist            as PackingListFlag,
      pck.posted           as Posted,
      pck.pldate           as PackingListDate,
      // measures
      @DefaultAggregation: #SUM
      cast( pck.grosswt as abap.dec( 15, 3 ) ) as GrossWeight,
      @DefaultAggregation: #SUM
      cast( pck.tarewt as abap.dec( 15, 3 ) ) as TareWeight,
      @DefaultAggregation: #SUM
      cast( pck.netwt as abap.dec( 15, 3 ) ) as NetWeight,
      @DefaultAggregation: #SUM
      @EndUserText.label: 'Record Count'
      cast( 1 as abap.int4 ) as RecordCount
}
