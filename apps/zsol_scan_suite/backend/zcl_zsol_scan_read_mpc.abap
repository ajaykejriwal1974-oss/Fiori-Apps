class ZCL_ZSOL_SCAN_READ_MPC definition
  public
  inheriting from /IWBEP/CL_MGW_PUSH_ABS_MODEL
  create public .

public section.

* ----------------------------------------------------------------------
* Scan Suite - guarded replacements for four CDS-published services.
*
* ZSOL_SO_PICK_PEND_CDS, ZSOL_PLIST_CDS, ZSOL_HUINV_HDR_PUSH_CDS and
* ZSOL_HUINV_ITM_PUSH_CDS are generated from @OData.publish annotations
* and run on CL_SADL_GTK_EXPOSURE_DPC, which is FINAL and SAP-owned.
* There is no DPC_EXT to extend, so the session check every other scanner
* service performs cannot be added to them. Anyone holding the shared
* warehouse SAP credential could read them directly - including the open
* order book with customer names - without ever signing in to the app.
*
* This service serves the same four reads from the same four CDS views,
* through a data provider we own and can guard.
*
* Property names are deliberately identical to the ones SADL emits, so
* the app's field handling does not change - only the service root.
*
* The projection is narrower than the CDS views on purpose: only the
* fields the app actually reads are exposed. Quantities and times are
* left out rather than re-typed, so nothing silently changes shape on
* the wire. Add a field here when a screen genuinely needs it.
*
* Two dates are exposed, both as Edm.String carrying YYYYMMDD rather
* than Edm.DateTime. YYYYMMDD sorts and compares correctly as a string,
* so "ge '20260601' and le '20260930'" needs no date conversion on
* either side, and every other property here is already a string.
*
*   DELIV_DATE  requested delivery date (VBAK-VDATU)
*   CREATED_ON  order creation date (VBAK-ERDAT)
*
* CREATED_ON is the one that makes the pending list usable. Open items
* carry requested delivery dates going back years - 2017 on this system -
* so filtering on DELIV_DATE returns almost nothing for a recent window
* and everything otherwise. Order creation date is what somebody means
* when they ask for recent orders.
*
* The old services stay active and untouched: SOLSYNCH's Android scanner
* calls ZSOL_SO_PICK_PEND_CDS under its own SAP user. Once the app runs
* on this service, the four CDS services should be removed from the
* shared account's role instead of being switched off.
*
* A FIFTH SET, ZSOL_RESERVATION (06.09.2026): open manual reservations
* for the HU Movement screen's reservation dropdown. Not a CDS
* replacement - read straight from RESB/RKPF in the data provider.
*
* SIXTH AND SEVENTH (06.09.2026): ZSOL_SO_BOXCHECK - per item of a sales
* order, why the Packing List does or does not offer boxes (the rules of
* ZRPT_SALES_SCAN applied to the packed stock, see
* ZCL_ZSOL_SO_BOXCHECK) - and ZSOL_SO_BATCH, the batches named on the
* order's items (ZVBAP_BATCH), the one set in this service that can be
* written to: POST assigns a batch, DELETE removes one, both behind the
* SOCHG grant.
* ----------------------------------------------------------------------

  types:
    begin of TS_PICK_PEND,
      SHIP_POINT  type c length 4,
      VBELN       type c length 10,
      POSNR       type c length 6,
      SHIPTO      type c length 10,
      SHIPTOPARTY type c length 35,
      SOLDTO      type c length 10,
      SOLDTOPARTY type c length 35,
      DELIV_DATE  type c length 8,
      CREATED_ON  type c length 8,
    end of TS_PICK_PEND .
  types:
    TT_PICK_PEND type standard table of TS_PICK_PEND .

  types:
    begin of TS_PLIST,
      BOXNO type c length 10,
      VBELN type c length 10,
      POSNR type c length 6,
      PKLST type c length 6,
      MATNR type c length 40,
      PTYPE type c length 2,
      GRADE type c length 1,
      HUCHK type c length 1,
    end of TS_PLIST .
  types:
    TT_PLIST type standard table of TS_PLIST .

  types:
    begin of TS_INV_HDR,
      HUINV_NR  type c length 10,
      WERKS     type c length 4,
      CREA_USER type c length 12,
    end of TS_INV_HDR .
  types:
    TT_INV_HDR type standard table of TS_INV_HDR .

  types:
    begin of TS_INV_ITM,
      HUINV_NR type c length 10,
      EXIDV    type c length 20,
      MATNR    type c length 40,
      CHARG    type c length 10,
      LGORT    type c length 4,
      VHILM    type c length 40,
      INV_BY   type c length 12,
    end of TS_INV_ITM .
  types:
    TT_INV_ITM type standard table of TS_INV_ITM .

* Open manual reservations for the HU Movement screen (06.09.2026).
* One row per open reservation item: what is reserved, where it is now
* (WERKS/LGORT) and where it goes (UMWRK/UMLGO). OPEN_QTY is
* BDMNG - ENMNG as a plain decimal string, MEINS its unit. Dates are
* YYYYMMDD strings like everywhere else in this service.
  types:
    begin of TS_RESV,
      RSNUM    type c length 10,
      RSPOS    type c length 4,
      BWART    type c length 3,
      MATNR    type c length 40,
      MAKTX    type c length 40,
      WERKS    type c length 4,
      LGORT    type c length 4,
      UMWRK    type c length 4,
      UMLGO    type c length 4,
      OPEN_QTY type c length 17,
      MEINS    type c length 3,
      RSDAT    type c length 8,
      BDTER    type c length 8,
      WEMPF    type c length 12,
      SGTXT    type c length 50,
    end of TS_RESV .
  types:
    TT_RESV type standard table of TS_RESV .

* Why an order shows no boxes (06.09.2026) - one row per sales order
* item, produced by ZCL_ZSOL_SO_BOXCHECK=>CHECK_ORDER. Quantities are
* plain decimal strings, counts Edm.Int32, everything else text; the
* OTHER_* and NEED_BATCH fields carry "value×count" lists ready to show.
  types:
    begin of TS_SO_CHECK,
      VBELN       type c length 10,
      POSNR       type c length 6,
      MATNR       type c length 40,
      ARKTX       type c length 40,
      WERKS       type c length 4,
      LGORT       type c length 4,
      CHARG       type c length 10,
      KWMENG      type c length 17,
      VRKME       type c length 3,
      DIS_QTY     type c length 17,
      OPEN_QTY    type c length 17,
      ABGRU       type c length 2,
      ZZSIZE      type c length 4,
      ZZSIZ1      type c length 4,
      ZZSIZ2      type c length 4,
      ZZGRADE     type c length 1,
      ZZGRAD1     type c length 1,
      ZZGRAD2     type c length 1,
      SO_BATCHES  type c length 120,
      BATCH_SRC   type c length 1,
      CAND_CNT    type i,
      MATCH_CNT   type i,
      MATCH_WT    type c length 17,
      NEED_BATCH  type c length 220,
      OTHER_LGORT type c length 120,
      OTHER_SIZE  type c length 120,
      OTHER_GRADE type c length 120,
      OTHER_SO    type c length 120,
      ON_DELIV    type i,
      NOT_POSTED  type i,
      HINT        type c length 220,
    end of TS_SO_CHECK .
  types:
    TT_SO_CHECK type standard table of TS_SO_CHECK with default key .

* A batch named on a sales order item (ZVBAP_BATCH). POST assigns one,
* DELETE removes it - both need the SOCHG screen grant. MESSAGE carries
* the outcome of a write.
  types:
    begin of TS_SO_BATCH,
      VBELN   type c length 10,
      POSNR   type c length 6,
      CHARG   type c length 10,
      MESSAGE type c length 220,
    end of TS_SO_BATCH .
  types:
    TT_SO_BATCH type standard table of TS_SO_BATCH with default key .

  methods DEFINE
    redefinition .
  methods GET_LAST_MODIFIED
    redefinition .

protected section.
private section.

  methods DEF_PICK_PEND
    raising /IWBEP/CX_MGW_MED_EXCEPTION .
  methods DEF_PLIST
    raising /IWBEP/CX_MGW_MED_EXCEPTION .
  methods DEF_INV_HDR
    raising /IWBEP/CX_MGW_MED_EXCEPTION .
  methods DEF_INV_ITM
    raising /IWBEP/CX_MGW_MED_EXCEPTION .
  methods DEF_RESV
    raising /IWBEP/CX_MGW_MED_EXCEPTION .
  methods DEF_SO_CHECK
    raising /IWBEP/CX_MGW_MED_EXCEPTION .
  methods DEF_SO_BATCH
    raising /IWBEP/CX_MGW_MED_EXCEPTION .

ENDCLASS.



CLASS ZCL_ZSOL_SCAN_READ_MPC IMPLEMENTATION.


  METHOD define.

    model->set_schema_namespace( 'ZSOL_SCAN_READ_SRV' ).

    def_pick_pend( ).
    def_plist( ).
    def_inv_hdr( ).
    def_inv_itm( ).
    def_resv( ).
    def_so_check( ).
    def_so_batch( ).

  ENDMETHOD.


  METHOD get_last_modified.

    " Stamps the metadata document so consumers cache correctly. Bump it
    " whenever an entity type here changes.
    CONSTANTS lc_gen_date_time TYPE timestamp VALUE '20260906160000'.

    rv_last_modified = super->get_last_modified( ).
    IF rv_last_modified LT lc_gen_date_time.
      rv_last_modified = lc_gen_date_time.
    ENDIF.

  ENDMETHOD.


  METHOD def_pick_pend.

    " Entity set name matches the SADL one exactly - the app's path
    " /ZSOL_SO_PICK_PEND?$format=json is unchanged.
    DATA lo_entity_type TYPE REF TO /iwbep/if_mgw_odata_entity_typ.
    DATA lo_property    TYPE REF TO /iwbep/if_mgw_odata_property.
    DATA lo_entity_set  TYPE REF TO /iwbep/if_mgw_odata_entity_set.

    lo_entity_type = model->create_entity_type(
      iv_entity_type_name = 'PickPend'
      iv_def_entity_set   = abap_false ).

    lo_property = lo_entity_type->create_property(
      iv_property_name = 'Ship_point' iv_abap_fieldname = 'SHIP_POINT' ).
    lo_property->set_is_key( ).
    lo_property->set_type_edm_string( ).
    lo_property->set_maxlength( iv_max_length = 4 ).
    lo_property->set_creatable( abap_false ).
    lo_property->set_updatable( abap_false ).
    lo_property->set_nullable( abap_false ).

    lo_property = lo_entity_type->create_property(
      iv_property_name = 'vbeln' iv_abap_fieldname = 'VBELN' ).
    lo_property->set_is_key( ).
    lo_property->set_type_edm_string( ).
    lo_property->set_maxlength( iv_max_length = 10 ).
    lo_property->set_creatable( abap_false ).
    lo_property->set_updatable( abap_false ).
    lo_property->set_nullable( abap_false ).

    lo_property = lo_entity_type->create_property(
      iv_property_name = 'posnr' iv_abap_fieldname = 'POSNR' ).
    lo_property->set_is_key( ).
    lo_property->set_type_edm_string( ).
    lo_property->set_maxlength( iv_max_length = 6 ).
    lo_property->set_creatable( abap_false ).
    lo_property->set_updatable( abap_false ).
    lo_property->set_nullable( abap_false ).

    lo_property = lo_entity_type->create_property(
      iv_property_name = 'ShipTo' iv_abap_fieldname = 'SHIPTO' ).
    lo_property->set_type_edm_string( ).
    lo_property->set_maxlength( iv_max_length = 10 ).
    lo_property->set_creatable( abap_false ).
    lo_property->set_updatable( abap_false ).

    lo_property = lo_entity_type->create_property(
      iv_property_name = 'ShipToParty' iv_abap_fieldname = 'SHIPTOPARTY' ).
    lo_property->set_type_edm_string( ).
    lo_property->set_maxlength( iv_max_length = 35 ).
    lo_property->set_creatable( abap_false ).
    lo_property->set_updatable( abap_false ).

    lo_property = lo_entity_type->create_property(
      iv_property_name = 'SoldTo' iv_abap_fieldname = 'SOLDTO' ).
    lo_property->set_type_edm_string( ).
    lo_property->set_maxlength( iv_max_length = 10 ).
    lo_property->set_creatable( abap_false ).
    lo_property->set_updatable( abap_false ).

    lo_property = lo_entity_type->create_property(
      iv_property_name = 'SoldToParty' iv_abap_fieldname = 'SOLDTOPARTY' ).
    lo_property->set_type_edm_string( ).
    lo_property->set_maxlength( iv_max_length = 35 ).
    lo_property->set_creatable( abap_false ).
    lo_property->set_updatable( abap_false ).

    " Requested delivery date (VBAK-VDATU) as YYYYMMDD.
    lo_property = lo_entity_type->create_property(
      iv_property_name = 'deliv_date' iv_abap_fieldname = 'DELIV_DATE' ).
    lo_property->set_type_edm_string( ).
    lo_property->set_maxlength( iv_max_length = 8 ).
    lo_property->set_creatable( abap_false ).
    lo_property->set_updatable( abap_false ).
    lo_property->set_filterable( abap_true ).
    lo_property->set_sortable( abap_true ).

    " Order creation date (VBAK-ERDAT) as YYYYMMDD. This is the one the
    " app should filter on:
    "   $filter=created_on ge '20260101'
    lo_property = lo_entity_type->create_property(
      iv_property_name = 'created_on' iv_abap_fieldname = 'CREATED_ON' ).
    lo_property->set_type_edm_string( ).
    lo_property->set_maxlength( iv_max_length = 8 ).
    lo_property->set_creatable( abap_false ).
    lo_property->set_updatable( abap_false ).
    lo_property->set_filterable( abap_true ).
    lo_property->set_sortable( abap_true ).

    lo_entity_type->bind_structure(
      iv_structure_name = 'ZCL_ZSOL_SCAN_READ_MPC=>TS_PICK_PEND' ).

    lo_entity_set = lo_entity_type->create_entity_set( 'ZSOL_SO_PICK_PEND' ).
    lo_entity_set->set_creatable( abap_false ).
    lo_entity_set->set_updatable( abap_false ).
    lo_entity_set->set_deletable( abap_false ).
    lo_entity_set->set_pageable( abap_true ).
    lo_entity_set->set_addressable( abap_true ).
    lo_entity_set->set_has_ftxt_search( abap_false ).
    lo_entity_set->set_subscribable( abap_false ).
    lo_entity_set->set_filter_required( abap_false ).

  ENDMETHOD.


  METHOD def_plist.

    DATA lo_entity_type TYPE REF TO /iwbep/if_mgw_odata_entity_typ.
    DATA lo_property    TYPE REF TO /iwbep/if_mgw_odata_property.
    DATA lo_entity_set  TYPE REF TO /iwbep/if_mgw_odata_entity_set.

    lo_entity_type = model->create_entity_type(
      iv_entity_type_name = 'PList'
      iv_def_entity_set   = abap_false ).

    lo_property = lo_entity_type->create_property(
      iv_property_name = 'boxno' iv_abap_fieldname = 'BOXNO' ).
    lo_property->set_is_key( ).
    lo_property->set_type_edm_string( ).
    lo_property->set_maxlength( iv_max_length = 10 ).
    lo_property->set_creatable( abap_false ).
    lo_property->set_updatable( abap_false ).
    lo_property->set_nullable( abap_false ).

    lo_property = lo_entity_type->create_property(
      iv_property_name = 'vbeln' iv_abap_fieldname = 'VBELN' ).
    lo_property->set_type_edm_string( ).
    lo_property->set_maxlength( iv_max_length = 10 ).
    lo_property->set_creatable( abap_false ).
    lo_property->set_updatable( abap_false ).

    lo_property = lo_entity_type->create_property(
      iv_property_name = 'posnr' iv_abap_fieldname = 'POSNR' ).
    lo_property->set_type_edm_string( ).
    lo_property->set_maxlength( iv_max_length = 6 ).
    lo_property->set_creatable( abap_false ).
    lo_property->set_updatable( abap_false ).

    lo_property = lo_entity_type->create_property(
      iv_property_name = 'pklst' iv_abap_fieldname = 'PKLST' ).
    lo_property->set_type_edm_string( ).
    lo_property->set_maxlength( iv_max_length = 6 ).
    lo_property->set_creatable( abap_false ).
    lo_property->set_updatable( abap_false ).

    lo_property = lo_entity_type->create_property(
      iv_property_name = 'matnr' iv_abap_fieldname = 'MATNR' ).
    lo_property->set_type_edm_string( ).
    lo_property->set_maxlength( iv_max_length = 40 ).
    lo_property->set_creatable( abap_false ).
    lo_property->set_updatable( abap_false ).

    lo_property = lo_entity_type->create_property(
      iv_property_name = 'ptype' iv_abap_fieldname = 'PTYPE' ).
    lo_property->set_type_edm_string( ).
    lo_property->set_maxlength( iv_max_length = 2 ).
    lo_property->set_creatable( abap_false ).
    lo_property->set_updatable( abap_false ).

    lo_property = lo_entity_type->create_property(
      iv_property_name = 'grade' iv_abap_fieldname = 'GRADE' ).
    lo_property->set_type_edm_string( ).
    lo_property->set_maxlength( iv_max_length = 1 ).
    lo_property->set_creatable( abap_false ).
    lo_property->set_updatable( abap_false ).

    lo_property = lo_entity_type->create_property(
      iv_property_name = 'HUCHK' iv_abap_fieldname = 'HUCHK' ).
    lo_property->set_type_edm_string( ).
    lo_property->set_maxlength( iv_max_length = 1 ).
    lo_property->set_creatable( abap_false ).
    lo_property->set_updatable( abap_false ).

    lo_entity_type->bind_structure(
      iv_structure_name = 'ZCL_ZSOL_SCAN_READ_MPC=>TS_PLIST' ).

    lo_entity_set = lo_entity_type->create_entity_set( 'ZSOL_PLIST' ).
    lo_entity_set->set_creatable( abap_false ).
    lo_entity_set->set_updatable( abap_false ).
    lo_entity_set->set_deletable( abap_false ).
    lo_entity_set->set_pageable( abap_true ).
    lo_entity_set->set_addressable( abap_true ).
    lo_entity_set->set_has_ftxt_search( abap_false ).
    lo_entity_set->set_subscribable( abap_false ).
    lo_entity_set->set_filter_required( abap_false ).

  ENDMETHOD.


  METHOD def_inv_hdr.

    DATA lo_entity_type TYPE REF TO /iwbep/if_mgw_odata_entity_typ.
    DATA lo_property    TYPE REF TO /iwbep/if_mgw_odata_property.
    DATA lo_entity_set  TYPE REF TO /iwbep/if_mgw_odata_entity_set.

    lo_entity_type = model->create_entity_type(
      iv_entity_type_name = 'InvHdr'
      iv_def_entity_set   = abap_false ).

    lo_property = lo_entity_type->create_property(
      iv_property_name = 'huinv_nr' iv_abap_fieldname = 'HUINV_NR' ).
    lo_property->set_is_key( ).
    lo_property->set_type_edm_string( ).
    lo_property->set_maxlength( iv_max_length = 10 ).
    lo_property->set_creatable( abap_false ).
    lo_property->set_updatable( abap_false ).
    lo_property->set_nullable( abap_false ).

    lo_property = lo_entity_type->create_property(
      iv_property_name = 'werks' iv_abap_fieldname = 'WERKS' ).
    lo_property->set_type_edm_string( ).
    lo_property->set_maxlength( iv_max_length = 4 ).
    lo_property->set_creatable( abap_false ).
    lo_property->set_updatable( abap_false ).

    lo_property = lo_entity_type->create_property(
      iv_property_name = 'crea_user' iv_abap_fieldname = 'CREA_USER' ).
    lo_property->set_type_edm_string( ).
    lo_property->set_maxlength( iv_max_length = 12 ).
    lo_property->set_creatable( abap_false ).
    lo_property->set_updatable( abap_false ).

    lo_entity_type->bind_structure(
      iv_structure_name = 'ZCL_ZSOL_SCAN_READ_MPC=>TS_INV_HDR' ).

    lo_entity_set = lo_entity_type->create_entity_set( 'ZSOL_HUINV_HDR_PUSH' ).
    lo_entity_set->set_creatable( abap_false ).
    lo_entity_set->set_updatable( abap_false ).
    lo_entity_set->set_deletable( abap_false ).
    lo_entity_set->set_pageable( abap_true ).
    lo_entity_set->set_addressable( abap_true ).
    lo_entity_set->set_has_ftxt_search( abap_false ).
    lo_entity_set->set_subscribable( abap_false ).
    lo_entity_set->set_filter_required( abap_false ).

  ENDMETHOD.


  METHOD def_inv_itm.

    DATA lo_entity_type TYPE REF TO /iwbep/if_mgw_odata_entity_typ.
    DATA lo_property    TYPE REF TO /iwbep/if_mgw_odata_property.
    DATA lo_entity_set  TYPE REF TO /iwbep/if_mgw_odata_entity_set.

    lo_entity_type = model->create_entity_type(
      iv_entity_type_name = 'InvItm'
      iv_def_entity_set   = abap_false ).

    lo_property = lo_entity_type->create_property(
      iv_property_name = 'huinv_nr' iv_abap_fieldname = 'HUINV_NR' ).
    lo_property->set_is_key( ).
    lo_property->set_type_edm_string( ).
    lo_property->set_maxlength( iv_max_length = 10 ).
    lo_property->set_creatable( abap_false ).
    lo_property->set_updatable( abap_false ).
    lo_property->set_nullable( abap_false ).

    lo_property = lo_entity_type->create_property(
      iv_property_name = 'exidv' iv_abap_fieldname = 'EXIDV' ).
    lo_property->set_is_key( ).
    lo_property->set_type_edm_string( ).
    lo_property->set_maxlength( iv_max_length = 20 ).
    lo_property->set_creatable( abap_false ).
    lo_property->set_updatable( abap_false ).
    lo_property->set_nullable( abap_false ).

    lo_property = lo_entity_type->create_property(
      iv_property_name = 'matnr' iv_abap_fieldname = 'MATNR' ).
    lo_property->set_type_edm_string( ).
    lo_property->set_maxlength( iv_max_length = 40 ).
    lo_property->set_creatable( abap_false ).
    lo_property->set_updatable( abap_false ).

    lo_property = lo_entity_type->create_property(
      iv_property_name = 'charg' iv_abap_fieldname = 'CHARG' ).
    lo_property->set_type_edm_string( ).
    lo_property->set_maxlength( iv_max_length = 10 ).
    lo_property->set_creatable( abap_false ).
    lo_property->set_updatable( abap_false ).

    lo_property = lo_entity_type->create_property(
      iv_property_name = 'lgort' iv_abap_fieldname = 'LGORT' ).
    lo_property->set_type_edm_string( ).
    lo_property->set_maxlength( iv_max_length = 4 ).
    lo_property->set_creatable( abap_false ).
    lo_property->set_updatable( abap_false ).

    lo_property = lo_entity_type->create_property(
      iv_property_name = 'vhilm' iv_abap_fieldname = 'VHILM' ).
    lo_property->set_type_edm_string( ).
    lo_property->set_maxlength( iv_max_length = 40 ).
    lo_property->set_creatable( abap_false ).
    lo_property->set_updatable( abap_false ).

    lo_property = lo_entity_type->create_property(
      iv_property_name = 'inv_by' iv_abap_fieldname = 'INV_BY' ).
    lo_property->set_type_edm_string( ).
    lo_property->set_maxlength( iv_max_length = 12 ).
    lo_property->set_creatable( abap_false ).
    lo_property->set_updatable( abap_false ).

    lo_entity_type->bind_structure(
      iv_structure_name = 'ZCL_ZSOL_SCAN_READ_MPC=>TS_INV_ITM' ).

    lo_entity_set = lo_entity_type->create_entity_set( 'ZSOL_HUINV_ITM_PUSH' ).
    lo_entity_set->set_creatable( abap_false ).
    lo_entity_set->set_updatable( abap_false ).
    lo_entity_set->set_deletable( abap_false ).
    lo_entity_set->set_pageable( abap_true ).
    lo_entity_set->set_addressable( abap_true ).
    lo_entity_set->set_has_ftxt_search( abap_false ).
    lo_entity_set->set_subscribable( abap_false ).
    lo_entity_set->set_filter_required( abap_false ).

  ENDMETHOD.


  METHOD def_resv.

    " Open manual reservations (RESB with RKPF) for the HU Movement
    " screen's reservation dropdown. Every property is a string; the two
    " keys are the reservation number and item.
    TYPES: BEGIN OF ty_def,
             name  TYPE string,
             field TYPE string,
             len   TYPE i,
           END OF ty_def.

    DATA lo_entity_type TYPE REF TO /iwbep/if_mgw_odata_entity_typ.
    DATA lo_property    TYPE REF TO /iwbep/if_mgw_odata_property.
    DATA lo_entity_set  TYPE REF TO /iwbep/if_mgw_odata_entity_set.
    DATA lt_def         TYPE STANDARD TABLE OF ty_def WITH EMPTY KEY.

    lo_entity_type = model->create_entity_type(
      iv_entity_type_name = 'Reservation'
      iv_def_entity_set   = abap_false ).

    lo_property = lo_entity_type->create_property(
      iv_property_name = 'rsnum' iv_abap_fieldname = 'RSNUM' ).
    lo_property->set_is_key( ).
    lo_property->set_type_edm_string( ).
    lo_property->set_maxlength( iv_max_length = 10 ).
    lo_property->set_creatable( abap_false ).
    lo_property->set_updatable( abap_false ).
    lo_property->set_nullable( abap_false ).

    lo_property = lo_entity_type->create_property(
      iv_property_name = 'rspos' iv_abap_fieldname = 'RSPOS' ).
    lo_property->set_is_key( ).
    lo_property->set_type_edm_string( ).
    lo_property->set_maxlength( iv_max_length = 4 ).
    lo_property->set_creatable( abap_false ).
    lo_property->set_updatable( abap_false ).
    lo_property->set_nullable( abap_false ).

    lt_def = VALUE #( ( name = 'bwart'    field = 'BWART'    len = 3 )
                      ( name = 'matnr'    field = 'MATNR'    len = 40 )
                      ( name = 'maktx'    field = 'MAKTX'    len = 40 )
                      ( name = 'werks'    field = 'WERKS'    len = 4 )
                      ( name = 'lgort'    field = 'LGORT'    len = 4 )
                      ( name = 'umwrk'    field = 'UMWRK'    len = 4 )
                      ( name = 'umlgo'    field = 'UMLGO'    len = 4 )
                      ( name = 'open_qty' field = 'OPEN_QTY' len = 17 )
                      ( name = 'meins'    field = 'MEINS'    len = 3 )
                      ( name = 'rsdat'    field = 'RSDAT'    len = 8 )
                      ( name = 'bdter'    field = 'BDTER'    len = 8 )
                      ( name = 'wempf'    field = 'WEMPF'    len = 12 )
                      ( name = 'sgtxt'    field = 'SGTXT'    len = 50 ) ).

    LOOP AT lt_def INTO DATA(ls_def).
      lo_property = lo_entity_type->create_property(
        iv_property_name  = CONV #( ls_def-name )
        iv_abap_fieldname = CONV #( ls_def-field ) ).
      lo_property->set_type_edm_string( ).
      lo_property->set_maxlength( iv_max_length = ls_def-len ).
      lo_property->set_creatable( abap_false ).
      lo_property->set_updatable( abap_false ).
    ENDLOOP.

    lo_entity_type->bind_structure(
      iv_structure_name = 'ZCL_ZSOL_SCAN_READ_MPC=>TS_RESV' ).

    lo_entity_set = lo_entity_type->create_entity_set( 'ZSOL_RESERVATION' ).
    lo_entity_set->set_creatable( abap_false ).
    lo_entity_set->set_updatable( abap_false ).
    lo_entity_set->set_deletable( abap_false ).
    lo_entity_set->set_pageable( abap_true ).
    lo_entity_set->set_addressable( abap_true ).
    lo_entity_set->set_has_ftxt_search( abap_false ).
    lo_entity_set->set_subscribable( abap_false ).
    lo_entity_set->set_filter_required( abap_false ).

  ENDMETHOD.

  METHOD def_so_check.

    " Why an order shows no boxes: one row per item. Read-only; keyed on
    " order and item.
    TYPES: BEGIN OF ty_def,
             name  TYPE string,
             field TYPE string,
             len   TYPE i,
           END OF ty_def.

    DATA lo_entity_type TYPE REF TO /iwbep/if_mgw_odata_entity_typ.
    DATA lo_property    TYPE REF TO /iwbep/if_mgw_odata_property.
    DATA lo_entity_set  TYPE REF TO /iwbep/if_mgw_odata_entity_set.
    DATA lt_def         TYPE STANDARD TABLE OF ty_def WITH EMPTY KEY.
    DATA lt_int         TYPE STANDARD TABLE OF ty_def WITH EMPTY KEY.

    lo_entity_type = model->create_entity_type(
      iv_entity_type_name = 'SoBoxCheck'
      iv_def_entity_set   = abap_false ).

    lo_property = lo_entity_type->create_property(
      iv_property_name = 'vbeln' iv_abap_fieldname = 'VBELN' ).
    lo_property->set_is_key( ).
    lo_property->set_type_edm_string( ).
    lo_property->set_maxlength( iv_max_length = 10 ).
    lo_property->set_creatable( abap_false ).
    lo_property->set_updatable( abap_false ).
    lo_property->set_nullable( abap_false ).

    lo_property = lo_entity_type->create_property(
      iv_property_name = 'posnr' iv_abap_fieldname = 'POSNR' ).
    lo_property->set_is_key( ).
    lo_property->set_type_edm_string( ).
    lo_property->set_maxlength( iv_max_length = 6 ).
    lo_property->set_creatable( abap_false ).
    lo_property->set_updatable( abap_false ).
    lo_property->set_nullable( abap_false ).

    lt_def = VALUE #( ( name = 'matnr'       field = 'MATNR'       len = 40 )
                      ( name = 'arktx'       field = 'ARKTX'       len = 40 )
                      ( name = 'werks'       field = 'WERKS'       len = 4 )
                      ( name = 'lgort'       field = 'LGORT'       len = 4 )
                      ( name = 'charg'       field = 'CHARG'       len = 10 )
                      ( name = 'kwmeng'      field = 'KWMENG'      len = 17 )
                      ( name = 'vrkme'       field = 'VRKME'       len = 3 )
                      ( name = 'dis_qty'     field = 'DIS_QTY'     len = 17 )
                      ( name = 'open_qty'    field = 'OPEN_QTY'    len = 17 )
                      ( name = 'abgru'       field = 'ABGRU'       len = 2 )
                      ( name = 'zzsize'      field = 'ZZSIZE'      len = 4 )
                      ( name = 'zzsiz1'      field = 'ZZSIZ1'      len = 4 )
                      ( name = 'zzsiz2'      field = 'ZZSIZ2'      len = 4 )
                      ( name = 'zzgrade'     field = 'ZZGRADE'     len = 1 )
                      ( name = 'zzgrad1'     field = 'ZZGRAD1'     len = 1 )
                      ( name = 'zzgrad2'     field = 'ZZGRAD2'     len = 1 )
                      ( name = 'so_batches'  field = 'SO_BATCHES'  len = 120 )
                      ( name = 'batch_src'   field = 'BATCH_SRC'   len = 1 )
                      ( name = 'match_wt'    field = 'MATCH_WT'    len = 17 )
                      ( name = 'need_batch'  field = 'NEED_BATCH'  len = 220 )
                      ( name = 'other_lgort' field = 'OTHER_LGORT' len = 120 )
                      ( name = 'other_size'  field = 'OTHER_SIZE'  len = 120 )
                      ( name = 'other_grade' field = 'OTHER_GRADE' len = 120 )
                      ( name = 'other_so'    field = 'OTHER_SO'    len = 120 )
                      ( name = 'hint'        field = 'HINT'        len = 220 ) ).

    LOOP AT lt_def INTO DATA(ls_def).
      lo_property = lo_entity_type->create_property(
        iv_property_name  = CONV #( ls_def-name )
        iv_abap_fieldname = CONV #( ls_def-field ) ).
      lo_property->set_type_edm_string( ).
      lo_property->set_maxlength( iv_max_length = ls_def-len ).
      lo_property->set_creatable( abap_false ).
      lo_property->set_updatable( abap_false ).
    ENDLOOP.

    lt_int = VALUE #( ( name = 'cand_cnt'   field = 'CAND_CNT' )
                      ( name = 'match_cnt'  field = 'MATCH_CNT' )
                      ( name = 'on_deliv'   field = 'ON_DELIV' )
                      ( name = 'not_posted' field = 'NOT_POSTED' ) ).

    LOOP AT lt_int INTO ls_def.
      lo_property = lo_entity_type->create_property(
        iv_property_name  = CONV #( ls_def-name )
        iv_abap_fieldname = CONV #( ls_def-field ) ).
      lo_property->set_type_edm_int32( ).
      lo_property->set_creatable( abap_false ).
      lo_property->set_updatable( abap_false ).
      lo_property->set_filterable( abap_false ).
    ENDLOOP.

    lo_entity_type->bind_structure(
      iv_structure_name = 'ZCL_ZSOL_SCAN_READ_MPC=>TS_SO_CHECK' ).

    lo_entity_set = lo_entity_type->create_entity_set( 'ZSOL_SO_BOXCHECK' ).
    lo_entity_set->set_creatable( abap_false ).
    lo_entity_set->set_updatable( abap_false ).
    lo_entity_set->set_deletable( abap_false ).
    lo_entity_set->set_pageable( abap_true ).
    lo_entity_set->set_addressable( abap_true ).
    lo_entity_set->set_has_ftxt_search( abap_false ).
    lo_entity_set->set_subscribable( abap_false ).
    lo_entity_set->set_filter_required( abap_false ).

  ENDMETHOD.


  METHOD def_so_batch.

    " The batches named on an order's items (ZVBAP_BATCH). The only set in
    " this service that takes a POST and a DELETE.
    DATA lo_entity_type TYPE REF TO /iwbep/if_mgw_odata_entity_typ.
    DATA lo_property    TYPE REF TO /iwbep/if_mgw_odata_property.
    DATA lo_entity_set  TYPE REF TO /iwbep/if_mgw_odata_entity_set.

    lo_entity_type = model->create_entity_type(
      iv_entity_type_name = 'SoBatch'
      iv_def_entity_set   = abap_false ).

    lo_property = lo_entity_type->create_property(
      iv_property_name = 'vbeln' iv_abap_fieldname = 'VBELN' ).
    lo_property->set_is_key( ).
    lo_property->set_type_edm_string( ).
    lo_property->set_maxlength( iv_max_length = 10 ).
    lo_property->set_creatable( abap_true ).
    lo_property->set_updatable( abap_false ).
    lo_property->set_nullable( abap_false ).

    lo_property = lo_entity_type->create_property(
      iv_property_name = 'posnr' iv_abap_fieldname = 'POSNR' ).
    lo_property->set_is_key( ).
    lo_property->set_type_edm_string( ).
    lo_property->set_maxlength( iv_max_length = 6 ).
    lo_property->set_creatable( abap_true ).
    lo_property->set_updatable( abap_false ).
    lo_property->set_nullable( abap_false ).

    lo_property = lo_entity_type->create_property(
      iv_property_name = 'charg' iv_abap_fieldname = 'CHARG' ).
    lo_property->set_is_key( ).
    lo_property->set_type_edm_string( ).
    lo_property->set_maxlength( iv_max_length = 10 ).
    lo_property->set_creatable( abap_true ).
    lo_property->set_updatable( abap_false ).
    lo_property->set_nullable( abap_false ).

    lo_property = lo_entity_type->create_property(
      iv_property_name = 'message' iv_abap_fieldname = 'MESSAGE' ).
    lo_property->set_type_edm_string( ).
    lo_property->set_maxlength( iv_max_length = 220 ).
    lo_property->set_creatable( abap_false ).
    lo_property->set_updatable( abap_false ).

    lo_entity_type->bind_structure(
      iv_structure_name = 'ZCL_ZSOL_SCAN_READ_MPC=>TS_SO_BATCH' ).

    lo_entity_set = lo_entity_type->create_entity_set( 'ZSOL_SO_BATCH' ).
    lo_entity_set->set_creatable( abap_true ).
    lo_entity_set->set_updatable( abap_false ).
    lo_entity_set->set_deletable( abap_true ).
    lo_entity_set->set_pageable( abap_true ).
    lo_entity_set->set_addressable( abap_true ).
    lo_entity_set->set_has_ftxt_search( abap_false ).
    lo_entity_set->set_subscribable( abap_false ).
    lo_entity_set->set_filter_required( abap_false ).

  ENDMETHOD.

ENDCLASS.
