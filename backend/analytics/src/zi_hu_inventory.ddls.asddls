@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'HU Inventory Analysis - Cube'
@Analytics: { dataCategory: #CUBE, dataExtraction.enabled: true }
@Metadata.allowExtensions: true
// Analytical cube over ZHUINV_ITEM. Replaces: ZHUINV_CLS, ZHUMO, ZHUREC.
// Old report variants are now dimensions; aggregate in the query.
define view entity ZI_HuInventoryCube
  as select from zhuinv_item
{
  key huinv_nr         as PhysInvDocument,
  key exidv            as HandlingUnit,
      matnr            as Material,
      charg            as Batch,
      lgort            as StorageLocation,
      vhilm            as PackagingMaterial,
      zind             as Status,
      inv_by           as CountedBy,
      inv_date         as CountDate,
      @DefaultAggregation: #SUM
      @Semantics.quantity.unitOfMeasure: 'BaseUnit'
      vemng            as CountedQuantity,
      @Semantics.unitOfMeasure: true
      meins            as BaseUnit,
      @DefaultAggregation: #SUM
      @EndUserText.label: 'Record Count'
      cast( 1 as abap.int4 ) as RecordCount
}
