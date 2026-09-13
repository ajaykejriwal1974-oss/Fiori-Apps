class ZCL_ZSOL_CHALLAN_PACK__MPC_EXT definition
  public
  inheriting from ZCL_ZSOL_CHALLAN_PACK__MPC
  create public .

* ----------------------------------------------------------------------
* Model extension for the Scan Suite Create Challan rework (06.09.2026).
*
* The generated model (SEGW project ZSOL_CHALLAN_PACK) has two entities,
* ChallanPack and ChallanPackBox, both built around delimited-string
* properties. The rework needs three plain lists the handheld can bind
* to directly, so they are added here rather than in the generated base
* class (which must not be edited):
*
*   PackingListSet     one row per sales order item + packing list that
*                      still has cartons to challan
*   PackingListBoxSet  the cartons of one packing list
*   TruckSet           ZTRCKMSTR trucks with their transporter
*
* The structures they bind to are declared in this class's public
* section. Their read logic is in ZCL_ZSOL_CHALLAN_PACK__DPC_EXT
* (redefinition of /IWBEP/IF_MGW_APPL_SRV_RUNTIME~GET_ENTITYSET).
*
* SECURITY CONFIRMS BEFORE THE CHALLAN (07.09.2026). The order of the
* two screens was inverted by the process owner: Packing List ->
* Security Loading -> Create Challan. Both screens now read the same two
* lists, told apart by a filterable MODE on PackingListSet:
*
*   Mode eq 'LOAD'     lists with cartons Security has still to confirm
*                      (Security Loading Scan)
*   Mode eq 'CHALLAN'  lists with at least one confirmed carton, which
*                      is what a challan can be made of (Create Challan)
*   no Mode            every pending list, as before
*
* PackingList carries LOADEDCOUNT (confirmed cartons) next to BOXCOUNT,
* and each PackingListBox says whether it is LOADED and when. The rule
* for "confirmed" is one place, ZCL_ZSOL_CHALLAN_PACK__DPC_EXT, and the
* posting class ZCL_ZSOL_OBD_CREATE applies the same rule when it packs.
*
* GET_LAST_MODIFIED is bumped so the Gateway metadata cache (in every
* system this is imported into) rebuilds the model without a manual
* /IWFND/CACHE_CLEANUP.
* ----------------------------------------------------------------------

public section.

  types:
    begin of ts_packinglist,
      so          type c length 10,
      soitem      type c length 6,
      pklst       type c length 6,
      pldate      type c length 8,
      boxcount    type i,
      loadedcount type i,
      netwt       type p length 7 decimals 3,
      plant       type c length 4,
      material    type c length 40,
      matdesc     type c length 40,
      customer    type c length 10,
      custname    type c length 35,
      mode        type c length 7,
    end of ts_packinglist .
  types:
    tt_packinglist type standard table of ts_packinglist with default key .

  types:
    begin of ts_packinglistbox,
      boxno      type c length 10,
      so         type c length 10,
      soitem     type c length 6,
      pklst      type c length 6,
      exidv      type c length 20,
      ptype      type c length 2,
      ptypetext  type c length 25,
      netwt      type p length 7 decimals 3,
      mergno     type c length 10,
      hustatus   type c length 4,
      loaded     type c length 1,
      loaddate   type c length 8,
      loadtime   type c length 6,
    end of ts_packinglistbox .
  types:
    tt_packinglistbox type standard table of ts_packinglistbox with default key .

  types:
    begin of ts_truck,
      trckno     type c length 10,
      trcode     type c length 6,
      trname     type c length 40,
    end of ts_truck .
  types:
    tt_truck type standard table of ts_truck with default key .

  constants gc_packinglist    type /iwbep/if_mgw_med_odata_types=>ty_e_med_entity_name value 'PackingList' ##NO_TEXT.
  constants gc_packinglistbox type /iwbep/if_mgw_med_odata_types=>ty_e_med_entity_name value 'PackingListBox' ##NO_TEXT.
  constants gc_truck          type /iwbep/if_mgw_med_odata_types=>ty_e_med_entity_name value 'Truck' ##NO_TEXT.

  methods DEFINE
    redefinition .
  methods GET_LAST_MODIFIED
    redefinition .
protected section.
private section.

  methods add_string_property
    importing
      !io_entity_type type ref to /iwbep/if_mgw_odata_entity_typ
      !iv_name        type string
      !iv_abap_name   type string
      !iv_length      type i
      !iv_key         type abap_bool default abap_false
      !iv_filterable  type abap_bool default abap_true
    raising
      /iwbep/cx_mgw_med_exception .

  methods add_int_property
    importing
      !io_entity_type type ref to /iwbep/if_mgw_odata_entity_typ
      !iv_name        type string
      !iv_abap_name   type string
    raising
      /iwbep/cx_mgw_med_exception .
ENDCLASS.



CLASS ZCL_ZSOL_CHALLAN_PACK__MPC_EXT IMPLEMENTATION.


  method add_string_property.
    data(lo_property) = io_entity_type->create_property( iv_property_name  = conv #( iv_name )
                                                         iv_abap_fieldname = conv #( iv_abap_name ) ).
    lo_property->set_type_edm_string( ).
    lo_property->set_maxlength( iv_max_length = iv_length ).
    if iv_key = abap_true.
      lo_property->set_is_key( ).
      lo_property->set_nullable( abap_false ).
    else.
      lo_property->set_nullable( abap_true ).
    endif.
    lo_property->set_creatable( abap_false ).
    lo_property->set_updatable( abap_false ).
    lo_property->set_sortable( abap_false ).
    lo_property->set_filterable( iv_filterable ).
  endmethod.


  method add_int_property.
    data(lo_property) = io_entity_type->create_property( iv_property_name  = conv #( iv_name )
                                                         iv_abap_fieldname = conv #( iv_abap_name ) ).
    lo_property->set_type_edm_int32( ).
    lo_property->set_creatable( abap_false ).
    lo_property->set_updatable( abap_false ).
    lo_property->set_sortable( abap_false ).
    lo_property->set_filterable( abap_false ).
  endmethod.


  method DEFINE.

    data: lo_entity_type type ref to /iwbep/if_mgw_odata_entity_typ,
          lo_property    type ref to /iwbep/if_mgw_odata_property,
          lo_entity_set  type ref to /iwbep/if_mgw_odata_entity_set.

    super->define( ).

*   ---- PackingList ----------------------------------------------------
    lo_entity_type = model->create_entity_type( iv_entity_type_name = gc_packinglist
                                                iv_def_entity_set   = abap_false ).
    add_string_property( io_entity_type = lo_entity_type iv_name = 'So'       iv_abap_name = 'SO'       iv_length = 10 iv_key = abap_true ).
    add_string_property( io_entity_type = lo_entity_type iv_name = 'SoItem'   iv_abap_name = 'SOITEM'   iv_length = 6  iv_key = abap_true ).
    add_string_property( io_entity_type = lo_entity_type iv_name = 'Pklst'    iv_abap_name = 'PKLST'    iv_length = 6  iv_key = abap_true ).
    add_string_property( io_entity_type = lo_entity_type iv_name = 'PlDate'   iv_abap_name = 'PLDATE'   iv_length = 8 ).
    add_int_property( io_entity_type = lo_entity_type iv_name = 'BoxCount'    iv_abap_name = 'BOXCOUNT' ).
    add_int_property( io_entity_type = lo_entity_type iv_name = 'LoadedCount' iv_abap_name = 'LOADEDCOUNT' ).
    lo_property = lo_entity_type->create_property( iv_property_name = 'NetWt' iv_abap_fieldname = 'NETWT' ).
    lo_property->set_type_edm_decimal( ).
    lo_property->set_precison( iv_precision = 3 ).
    lo_property->set_maxlength( iv_max_length = 13 ).
    lo_property->set_creatable( abap_false ).
    lo_property->set_updatable( abap_false ).
    lo_property->set_sortable( abap_false ).
    lo_property->set_filterable( abap_false ).
    add_string_property( io_entity_type = lo_entity_type iv_name = 'Plant'    iv_abap_name = 'PLANT'    iv_length = 4 ).
    add_string_property( io_entity_type = lo_entity_type iv_name = 'Material' iv_abap_name = 'MATERIAL' iv_length = 40 ).
    add_string_property( io_entity_type = lo_entity_type iv_name = 'MatDesc'  iv_abap_name = 'MATDESC'  iv_length = 40 ).
    add_string_property( io_entity_type = lo_entity_type iv_name = 'Customer' iv_abap_name = 'CUSTOMER' iv_length = 10 ).
    add_string_property( io_entity_type = lo_entity_type iv_name = 'CustName' iv_abap_name = 'CUSTNAME' iv_length = 35 ).
*   The screen asking: LOAD (Security Loading Scan) or CHALLAN (Create
*   Challan). A filter, echoed back in every row. See the class comment.
    add_string_property( io_entity_type = lo_entity_type iv_name = 'Mode'     iv_abap_name = 'MODE'     iv_length = 7 ).
    lo_entity_type->bind_structure( iv_structure_name = 'ZCL_ZSOL_CHALLAN_PACK__MPC_EXT=>TS_PACKINGLIST' ).
    lo_entity_set = lo_entity_type->create_entity_set( 'PackingListSet' ).
    lo_entity_set->set_creatable( abap_false ).
    lo_entity_set->set_updatable( abap_false ).
    lo_entity_set->set_deletable( abap_false ).
    lo_entity_set->set_pageable( abap_false ).
    lo_entity_set->set_addressable( abap_true ).
    lo_entity_set->set_has_ftxt_search( abap_false ).
    lo_entity_set->set_subscribable( abap_false ).
    lo_entity_set->set_filter_required( abap_false ).

*   ---- PackingListBox -------------------------------------------------
    lo_entity_type = model->create_entity_type( iv_entity_type_name = gc_packinglistbox
                                                iv_def_entity_set   = abap_false ).
    add_string_property( io_entity_type = lo_entity_type iv_name = 'Boxno'     iv_abap_name = 'BOXNO'     iv_length = 10 iv_key = abap_true ).
    add_string_property( io_entity_type = lo_entity_type iv_name = 'So'        iv_abap_name = 'SO'        iv_length = 10 ).
    add_string_property( io_entity_type = lo_entity_type iv_name = 'SoItem'    iv_abap_name = 'SOITEM'    iv_length = 6 ).
    add_string_property( io_entity_type = lo_entity_type iv_name = 'Pklst'     iv_abap_name = 'PKLST'     iv_length = 6 ).
    add_string_property( io_entity_type = lo_entity_type iv_name = 'Exidv'     iv_abap_name = 'EXIDV'     iv_length = 20 ).
    add_string_property( io_entity_type = lo_entity_type iv_name = 'Ptype'     iv_abap_name = 'PTYPE'     iv_length = 2 ).
    add_string_property( io_entity_type = lo_entity_type iv_name = 'PtypeText' iv_abap_name = 'PTYPETEXT' iv_length = 25 ).
    lo_property = lo_entity_type->create_property( iv_property_name = 'NetWt' iv_abap_fieldname = 'NETWT' ).
    lo_property->set_type_edm_decimal( ).
    lo_property->set_precison( iv_precision = 3 ).
    lo_property->set_maxlength( iv_max_length = 13 ).
    lo_property->set_creatable( abap_false ).
    lo_property->set_updatable( abap_false ).
    lo_property->set_sortable( abap_false ).
    lo_property->set_filterable( abap_false ).
    add_string_property( io_entity_type = lo_entity_type iv_name = 'Mergno'    iv_abap_name = 'MERGNO'    iv_length = 10 ).
    add_string_property( io_entity_type = lo_entity_type iv_name = 'HuStatus'  iv_abap_name = 'HUSTATUS'  iv_length = 4 ).
*   Security's confirmation of this carton (ZSOL_HUDISPATCH): 'X' when
*   confirmed since the packing list was made, with the scan date and
*   time (YYYYMMDD / HHMMSS). Display only.
    add_string_property( io_entity_type = lo_entity_type iv_name = 'Loaded'    iv_abap_name = 'LOADED'    iv_length = 1 iv_filterable = abap_false ).
    add_string_property( io_entity_type = lo_entity_type iv_name = 'LoadDate'  iv_abap_name = 'LOADDATE'  iv_length = 8 iv_filterable = abap_false ).
    add_string_property( io_entity_type = lo_entity_type iv_name = 'LoadTime'  iv_abap_name = 'LOADTIME'  iv_length = 6 iv_filterable = abap_false ).
    lo_entity_type->bind_structure( iv_structure_name = 'ZCL_ZSOL_CHALLAN_PACK__MPC_EXT=>TS_PACKINGLISTBOX' ).
    lo_entity_set = lo_entity_type->create_entity_set( 'PackingListBoxSet' ).
    lo_entity_set->set_creatable( abap_false ).
    lo_entity_set->set_updatable( abap_false ).
    lo_entity_set->set_deletable( abap_false ).
    lo_entity_set->set_pageable( abap_false ).
    lo_entity_set->set_addressable( abap_true ).
    lo_entity_set->set_has_ftxt_search( abap_false ).
    lo_entity_set->set_subscribable( abap_false ).
    lo_entity_set->set_filter_required( abap_true ).

*   ---- Truck ----------------------------------------------------------
    lo_entity_type = model->create_entity_type( iv_entity_type_name = gc_truck
                                                iv_def_entity_set   = abap_false ).
    add_string_property( io_entity_type = lo_entity_type iv_name = 'Trckno' iv_abap_name = 'TRCKNO' iv_length = 10 iv_key = abap_true ).
    add_string_property( io_entity_type = lo_entity_type iv_name = 'Trcode' iv_abap_name = 'TRCODE' iv_length = 6 ).
    add_string_property( io_entity_type = lo_entity_type iv_name = 'TrName' iv_abap_name = 'TRNAME' iv_length = 40 ).
    lo_entity_type->bind_structure( iv_structure_name = 'ZCL_ZSOL_CHALLAN_PACK__MPC_EXT=>TS_TRUCK' ).
    lo_entity_set = lo_entity_type->create_entity_set( 'TruckSet' ).
    lo_entity_set->set_creatable( abap_false ).
    lo_entity_set->set_updatable( abap_false ).
    lo_entity_set->set_deletable( abap_false ).
    lo_entity_set->set_pageable( abap_false ).
    lo_entity_set->set_addressable( abap_true ).
    lo_entity_set->set_has_ftxt_search( abap_false ).
    lo_entity_set->set_subscribable( abap_false ).
    lo_entity_set->set_filter_required( abap_false ).

  endmethod.


  method GET_LAST_MODIFIED.
*   Newer than the generated base class's stamp, so every Gateway
*   metadata cache picks the extended model up on first use. Bumped
*   07.09.2026 for Mode / LoadedCount / Loaded.
    constants lc_ext_date_time type timestamp value '20260907000000'.
    rv_last_modified = super->get_last_modified( ).
    if rv_last_modified lt lc_ext_date_time.
      rv_last_modified = lc_ext_date_time.
    endif.
  endmethod.
ENDCLASS.
