@EndUserText.label: 'Value help - Supplier Lot, open QC'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
@Search.searchable: true
// Value help for the Supplier Lot field on the QC worklists. Same open-lot
// test, same Plant and InspectionType keys and same auto-fill guards as
// ZI_VH_QC_BATCH - see the comments there.
//
// This is QALS-LICHN, the supplier's own reference, not QALS-CHARG.
//
// MEASURED 2026-08-29: LICHN is blank on all 152 inspection lots in KSD -
// every plant, every inspection type, open and closed alike. Nothing fills it
// here, because these lots are not raised against a goods receipt that carries
// a vendor batch. So this value help is correctly wired and will stay empty
// until that changes. The endpoint answers 200 with an empty collection; that
// is the data, not a fault.
//
// What an operator calls the supplier lot is QALS-CHARG on a type 01 or 08
// lot, exposed as GreigeLot. On those lots CHARG and the Batch field hold the
// same string, so ZI_VH_QC_BATCH already offers it. Checked on 010000000051
// in plant 2002: Batch = GreigeLot = AT1-5547, VendorBatch blank.
define view entity ZI_VH_QC_SUPPLIER_LOT
  as select from ZI_QC_INSP_LOT
{
      @EndUserText.label: 'Plant'
  key Plant,
      @EndUserText.label: 'Inspection Type'
  key InspectionType,
      @EndUserText.label: 'Supplier Lot'
      @Search.defaultSearchElement: true
  key VendorBatch,
      @EndUserText.label: 'Material'
      max(Material)                   as Material,
      @EndUserText.label: 'Description'
      max(MaterialName)               as MaterialName,
      @EndUserText.label: 'Materials'
      count(distinct Material)        as MaterialCount,
      @EndUserText.label: 'Production Order'
      max(ProductionOrder)            as ProductionOrder,
      @EndUserText.label: 'Orders'
      count(distinct ProductionOrder) as OrderCount,
      @EndUserText.label: 'Open Lots'
      count(*)                        as OpenLotCount
}
where
      IsOpen      =  'X'
  and VendorBatch <> ''
group by
  Plant,
  InspectionType,
  VendorBatch
