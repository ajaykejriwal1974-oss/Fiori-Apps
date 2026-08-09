@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'PO Closure - Cube'
@Analytics: { dataCategory: #CUBE, dataExtraction.enabled: true }
@Metadata.allowExtensions: true
// PO closure status cube - replaces ZPOCLOSE / ZPO_CLOSE (ZSOL_PO_CLOSE).
// Item-level over standard I_PurchaseOrderItem (+ header for Supplier/date).
// Open vs closed = standard completion flags (delivered / invoiced / deletion code).
define view entity ZI_PO_CLOSE
  as select from    I_PurchaseOrderItem as poi
    left outer join I_PurchaseOrder     as po on po.PurchaseOrder = poi.PurchaseOrder
{
  key poi.CompanyCode                       as CompanyCode,
  key poi.PurchaseOrder                     as PurchaseOrder,
  key poi.PurchaseOrderItem                 as PurchaseOrderItem,
      po.Supplier                           as Supplier,
      poi.Plant                             as Plant,
      poi.Material                          as Material,
      poi.PurchaseOrderItemText             as ItemText,
      poi.IsCompletelyDelivered             as IsCompletelyDelivered,
      poi.IsFinallyInvoiced                 as IsFinallyInvoiced,
      poi.PurchasingDocumentDeletionCode    as DeletionCode,
      poi.PurchaseOrderQuantityUnit         as OrderUnit,
      poi.DocumentCurrency                  as Currency,
      po.CreationDate                       as PoCreationDate,
      @DefaultAggregation: #SUM
      @Semantics.quantity.unitOfMeasure: 'OrderUnit'
      cast( poi.OrderQuantity as abap.dec( 15, 3 ) ) as OrderQuantity,
      @DefaultAggregation: #SUM
      @Semantics.amount.currencyCode: 'Currency'
      cast( poi.NetAmount as abap.dec( 15, 2 ) )     as NetAmount,
      @DefaultAggregation: #SUM
      @EndUserText.label: 'Record Count'
      cast( 1 as abap.int4 )                as RecordCount
}
