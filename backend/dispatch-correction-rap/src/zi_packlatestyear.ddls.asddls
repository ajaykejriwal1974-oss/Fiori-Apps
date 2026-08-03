@AccessControl.authorizationCheck: #NOT_ALLOWED
@EndUserText.label: 'Latest pack fiscal year per box - helper'
//
//  Helper for ZI_DispatchBox: ZPP_PACK is keyed by BOXNO + GJAHR, but the dispatch
//  table carries no year — joining on BOXNO alone multiplies each dispatch row by
//  the number of fiscal years the box appears in AND breaks ZI_DispatchBox's
//  declared "key boxno" uniqueness (an OData key collision). This view picks the
//  LATEST year per box so the main view can join deterministically to one row.
//
define view entity ZI_PackLatestYear
  as select from zpp_pack
{
  key boxno,
      max( gjahr ) as LatestYear
}
group by boxno
