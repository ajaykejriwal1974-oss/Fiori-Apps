@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Dispatch Register - Cube'
@Analytics: { dataCategory: #CUBE, dataExtraction.enabled: true }
@Metadata.allowExtensions: true
// Analytical cube over ZSOL_HUDISPATCH. Replaces: ZPWDIS, ZDISPATCH, ZPDESP (box-level).
// Old report variants are now dimensions; aggregate in the query.
define view entity ZI_DispatchRegisterCube
  as select from zsol_hudispatch
{
  key boxno            as Box,
      so               as SalesOrder,
      so_item          as SalesOrderItem,
      pck_lst          as PackListItem,
      status           as Status,
      erdat            as DispatchDate,
      @DefaultAggregation: #SUM
      @EndUserText.label: 'Record Count'
      cast( 1 as abap.int4 ) as RecordCount
}
