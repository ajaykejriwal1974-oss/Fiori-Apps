@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'GST Tax Register - Cube'
@Analytics: { dataCategory: #CUBE, dataExtraction.enabled: true }
@Metadata.allowExtensions: true
// Analytical cube over ZSOL_GST_DET. Replaces: ZGST, ZGST1, ZGST2, ZGSTCR (or standard GST/DRC).
// Old report variants are now dimensions; aggregate in the query.
define view entity ZI_GstTaxCube
  as select from zsol_gst_det
{
  key plant            as Plant,
  key vendor           as Vendor,
  key billto           as BillToParty,
      plant_state      as PlantState,
      vend_state       as VendorState,
      shipto           as ShipToParty,
      shipto_state     as ShipToState,
      billto_state     as BillToState,
      @DefaultAggregation: #SUM
      @EndUserText.label: 'Record Count'
      cast( 1 as abap.int4 ) as RecordCount
}
