@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Packed Stock / Packing (ZPP_PACK) - Cube'
@Analytics: { dataCategory: #CUBE, dataExtraction.enabled: true }
@Metadata.allowExtensions: true
// Single analytical cube over ZPP_PACK feeding BOTH the packed-stock analysis and
// the packing/dispatch register queries (audit P4 - one cube, many queries).
// Replaces the stock reports (ZBOXSTOCK, ZGSTOCK, ZPRP1, ZSSTOCK, ZDSTOCK, ZSTOCK,
// ZPRP, ZPRPSZ) AND the packing-list family (ZPLIST01..03(+A/T/N/D), ZPACKLIST*).
// Old report variants are now dimensions; aggregate in the query.
// ZZMARA is an APPEND STRUCTURE on MARA, not a table of its own - KSD rejected
// a direct join with "Table type of ZZMARA is not supported". Its fields are
// therefore columns of MARA, which is what is joined here. They carry the
// textile attributes the dispatch desk selects on in ZBOXSTOCK. ZPP_PACK
// already has ProductType (pltyp); Denier and Filament exist only on the
// material. Left outer join: a box whose material has no MARA row still
// appears, with blank denier/filament.
define view entity ZI_PACKED_STOCK
  as select from zpp_pack as pck
    left outer join mara as ext on ext.matnr = pck.matnr
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
      // ZBOXSTOCK selection fields - MARA append-structure (ZZMARA) columns
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
