@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Dyeing Recipe Master - Interface'
@Metadata.allowExtensions: true
// Custom master (Route 7) - managed RAP over legacy table ZPP_RECEIPE (ZRECP01/02/03).
// Field list mirrors the real Z-table (field dictionary). This legacy table
// has no TIMESTAMPL column, so the optimistic-concurrency ETag is omitted
// (add a TIMESTAMPL column to enable it). Code fields carry in-table text
// (@ObjectModel.text.element) and value helps (on the projection).
define root view entity ZI_Recipe
  as select from zpp_receipe
{
  key werks                  as Plant,
      @ObjectModel.text.element: ['GreyItemDesc']
  key grey_code              as GreyCode,
      @ObjectModel.text.element: ['DyeItemDesc']
  key dye_code               as DyeCode,
  key shdcd                  as ShadeCode,
  key posnr                  as ItemNumber,
      @Semantics.text: true
      grey_item              as GreyItemDesc,
      @Semantics.text: true
      dye_item               as DyeItemDesc,
      @ObjectModel.text.element: ['ComponentDesc']
      component              as Component,
      @Semantics.text: true
      comp_desc              as ComponentDesc,
      comp_type              as ComponentType,
      @Semantics.quantity.unitOfMeasure: 'SalesUnit'
      ratio                  as Ratio,
      @Semantics.unitOfMeasure: true
      vrkme                  as SalesUnit,
      remarks                as Remarks,
      @Semantics.user.createdBy: true
      ernam                  as CreatedBy,
      erdat                  as CreatedOnDate,
      erzet                  as CreatedAtTime,
      @Semantics.user.lastChangedBy: true
      lastuser               as LastChangedBy,
      lastdate               as LastChangedDate,
      lasttime               as LastChangedTime
}
