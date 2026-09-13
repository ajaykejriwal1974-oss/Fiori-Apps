class ZCL_ZSOL_CHALLAN_PACK__DPC_EXT definition
  public
  inheriting from ZCL_ZSOL_CHALLAN_PACK__DPC
  create public .

public section.

* ----------------------------------------------------------------------
* Every method here opens with ZCL_ZSOL_APP_AUTH=>CHECK_REQUEST, which
* verifies the app session token carried in the X-Scan-Token header.
*
* The handheld reaches SAP under one shared SAP account, so that account
* alone must not be enough to reach this service - CREATE_ENTITY posts:
* with App = 'X' it assigns packed boxes to their existing delivery (flags
* ZPP_PACK-HUPOST and appends an audit-log row); with App = 'D' it creates
* the delivery itself (see below). Both are real postings, not lookups.
*
* The reads ask only for a valid session, because the Create Challan
* screen and the Security Loading Scan screen both read them. The write
* is tied to the screen it belongs to, CHALLAN.
*
* ======================================================================
* CREATE CHALLAN REWORK (06.09.2026)
*
* Until now the app's Create Challan only logged cartons; the SAP challan
* (outbound delivery + packed HUs + goods issue) was made separately in
* ZSDOBDN. The operator also picked cartons one at a time from a dropdown.
*
* Now:
*   PackingListSet     GET  - order items with a packing list that still
*                             has cartons to challan (SO, item, PKLST,
*                             date, carton count, confirmed count, weight,
*                             material, customer). Optional filters
*                             So eq '...' and Mode eq 'LOAD' / 'CHALLAN'
*                             (below).
*   PackingListBoxSet  GET  - the cartons of one packing list, each with
*                             Loaded = 'X' when Security has confirmed it.
*                             Filter So, SoItem and Pklst are all required.
*   TruckSet           GET  - ZTRCKMSTR trucks with their transporter.
*   ChallanPackSet     POST - App = 'D': BoxData = "So|SoItem|Pklst|
*                             GiDate(YYYYMMDD)|Trcode|Trckno". Runs
*                             ZCL_ZSOL_OBD_CREATE, which does what ZSDOBDN
*                             does: delivery for the packing list, HUs
*                             packed, goods issue posted, LIKP transporter
*                             and truck, 621 for pallets/trolleys, log
*                             rows. Response: BoxData = "R|type|message;"
*                             then one "D|delivery|type|message;" per
*                             delivery created (or attempted); SoItemList
*                             = one "B|boxno|type|message;" per carton
*                             followed by "L|text;" lines from the VL01N
*                             and BAPI message logs.
*                             App = 'X' (the old per-box log) is kept for
*                             the Android scanner.
*
* The three new entity sets are declared in ZCL_ZSOL_CHALLAN_PACK__MPC_EXT
* and served by the redefinition of the generic GET_ENTITYSET below, so
* the generated SEGW classes stay untouched.
*
* ======================================================================
* SECURITY CONFIRMS BEFORE THE CHALLAN (07.09.2026)
*
* The process owner inverted the order of the last two screens. It is
* now Packing List -> Security Loading Scan -> Create Challan: Security
* scans the cartons of a packing list onto the vehicle first, and the
* challan is then made of the cartons Security confirmed. (Until 06.09
* the challan came first and Security confirmed its deliveries; ZSDOBDN
* has always insisted on the Security scan before the challan for
* ZSOL_LOCKDIS plants, so this restores that order for the app, for
* every plant.)
*
* Both screens read PackingListSet / PackingListBoxSet; the Mode filter
* on PackingListSet says which screen is asking:
*
*   Mode eq 'LOAD'     lists that still have cartons to confirm
*                      (LoadedCount < BoxCount) - the Security dropdown
*   Mode eq 'CHALLAN'  lists with at least one confirmed carton
*                      (LoadedCount > 0) - the Create Challan dropdown
*   no Mode            every pending list (as before)
*
* A CARTON IS "CONFIRMED" when ZSOL_HUDISPATCH has its row (one row per
* box number - the Security scan rewrites it) with STATUS other than
* 'E-' (ZCL_ZSOL_DISPATCH_ISCA_DPC_EXT's mark for a scan whose order and
* item did not match the packing record), PCK_LST equal to the carton's
* packing list and ERDAT on or after ZPP_PACK-PLDATE: Security scanned
* this carton for this list after the list was made. The same rule,
* written the same way, is in ZCL_ZSOL_OBD_CREATE, which packs only
* confirmed cartons onto the delivery and refuses a list with none.
*
* The Security screen's own write (IscanSet in ZSOL_DISPATCH_ISCAN_SRV)
* never depended on a delivery and is unchanged. ChallanPackSet's
* BoxData (deliveries pending Security) is kept for the Android scanner.
* ======================================================================
*
* Scoped to the caller's plants 2026-09-01. The SoItemList aggregate is
* the heaviest read in the suite - it groups every packed-but-unassigned
* box in ZPP_PACK, 31,061 rows out of 4,263,565 on KSD and a table of
* 27,329,939 rows on KSQ - and it was returning every plant's orders to
* every signed-in operator.
*
* The box dropdown authorises the sales order it is asked about, and the
* pack write authorises every distinct order in its payload before
* anything is packed. The boxes themselves need no separate check:
* ZCL_ZSOL_CHALLAN_PACK=>PACK_BOXES already skips any box whose ZPP_PACK
* record does not match the order and item it was submitted under, so a
* box cannot be carried in under an order the caller happens to hold.
*
* ZSOL_CHALLAN_LOG IS APPEND-ONLY FROM 02.09.2026. Its key gained GJAHR
* and LOGNO and PACK_BOXES now INSERTs instead of MODIFYing, so a box can
* have more than one row in it - one per Challan it has been packed onto.
* The pending-delivery aggregate below counts DISTINCT BOXNO rather than
* rows for that reason.
*
* ZSOL_HUDISPATCH IS KEYED MANDT + BOXNO AND NOTHING EVER DELETES FROM
* IT (03.09.2026): a dispatch row only clears a box if it is dated at or
* after the moment that box was packed onto the Challan (VEKP AEDAT/AEZET).
*
* ONLY BOXES THAT ARE ON THE PACKING LIST ARE "PENDING PACK" (05.09.2026):
* a box counts only if its handling unit still exists in VEKP in status
* 0020 or 0030 with VPOBJ 00, 06 or 12 - the ZSOL_PLIST conditions - and
* it carries a packing list number (PKLST). HUPOST is not read anywhere
* here; "already on a Challan" comes from ZSOL_CHALLAN_LOG (a log row for
* the same box, order and item dated on or after ZPP_PACK-PLDATE).
* ----------------------------------------------------------------------

  methods /IWBEP/IF_MGW_APPL_SRV_RUNTIME~GET_ENTITYSET
    redefinition .
protected section.

  methods CHALLANPACKSET_CREATE_ENTITY
    redefinition .
  methods CHALLANPACKSET_GET_ENTITYSET
    redefinition .
  methods CHALLANPACKBOXSE_GET_ENTITYSET
    redefinition .
private section.

  " Single EQ value of one $filter property, from the parsed select options.
  methods filter_value
    importing
      !it_filter      type /iwbep/t_mgw_select_option
      !iv_property    type string
    returning
      value(rv_value) type string .

  " Strips the two delimiters of the string-encoded response fields.
  methods clean
    importing
      !iv_text       type string
    returning
      value(rv_text) type string .

  methods get_packing_lists
    importing
      !is_session     type zcl_zsol_app_auth=>ty_session
      !iv_so          type string
      !iv_mode        type string
    returning
      value(rt_list)  type zcl_zsol_challan_pack__mpc_ext=>tt_packinglist
    raising
      /iwbep/cx_mgw_busi_exception .

  methods get_packing_list_boxes
    importing
      !is_session     type zcl_zsol_app_auth=>ty_session
      !iv_so          type string
      !iv_soitem      type string
      !iv_pklst       type string
    returning
      value(rt_boxes) type zcl_zsol_challan_pack__mpc_ext=>tt_packinglistbox
    raising
      /iwbep/cx_mgw_busi_exception .

  methods get_trucks
    returning
      value(rt_trucks) type zcl_zsol_challan_pack__mpc_ext=>tt_truck .

  methods create_challan
    importing
      !is_session type zcl_zsol_app_auth=>ty_session
      !iv_boxdata type string
    changing
      !cs_entity  type zcl_zsol_challan_pack__mpc=>ts_challanpack
    raising
      /iwbep/cx_mgw_busi_exception .
ENDCLASS.

CLASS ZCL_ZSOL_CHALLAN_PACK__DPC_EXT IMPLEMENTATION.

  METHOD /iwbep/if_mgw_appl_srv_runtime~get_entityset.

*   The three entity sets added in the MPC_EXT are served here; everything
*   the SEGW generator knows about goes to the generated dispatcher, whose
*   handlers run their own session check.
    DATA: ls_session TYPE zcl_zsol_app_auth=>ty_session,
          lt_filter  TYPE /iwbep/t_mgw_select_option.

    IF iv_entity_name = zcl_zsol_challan_pack__mpc_ext=>gc_packinglist
    OR iv_entity_name = zcl_zsol_challan_pack__mpc_ext=>gc_packinglistbox
    OR iv_entity_name = zcl_zsol_challan_pack__mpc_ext=>gc_truck.
      ls_session = zcl_zsol_app_auth=>check_request(
        io_tech_request_context->get_request_headers( ) ).
      lt_filter = io_tech_request_context->get_filter( )->get_filter_select_options( ).
    ENDIF.

    CASE iv_entity_name.

      WHEN zcl_zsol_challan_pack__mpc_ext=>gc_packinglist.
        DATA(lt_list) = get_packing_lists( is_session = ls_session
                                           iv_so      = filter_value( it_filter = lt_filter iv_property = 'So' )
                                           iv_mode    = filter_value( it_filter = lt_filter iv_property = 'Mode' ) ).
        copy_data_to_ref( EXPORTING is_data = lt_list
                          CHANGING  cr_data = er_entityset ).

      WHEN zcl_zsol_challan_pack__mpc_ext=>gc_packinglistbox.
        DATA(lt_boxes) = get_packing_list_boxes( is_session = ls_session
                                                 iv_so      = filter_value( it_filter = lt_filter iv_property = 'So' )
                                                 iv_soitem  = filter_value( it_filter = lt_filter iv_property = 'SoItem' )
                                                 iv_pklst   = filter_value( it_filter = lt_filter iv_property = 'Pklst' ) ).
        copy_data_to_ref( EXPORTING is_data = lt_boxes
                          CHANGING  cr_data = er_entityset ).

      WHEN zcl_zsol_challan_pack__mpc_ext=>gc_truck.
        DATA(lt_trucks) = get_trucks( ).
        copy_data_to_ref( EXPORTING is_data = lt_trucks
                          CHANGING  cr_data = er_entityset ).

      WHEN OTHERS.
        super->/iwbep/if_mgw_appl_srv_runtime~get_entityset(
          EXPORTING
            iv_entity_name           = iv_entity_name
            iv_entity_set_name       = iv_entity_set_name
            iv_source_name           = iv_source_name
            it_filter_select_options = it_filter_select_options
            is_paging                = is_paging
            it_key_tab               = it_key_tab
            it_navigation_path       = it_navigation_path
            it_order                 = it_order
            iv_filter_string         = iv_filter_string
            iv_search_string         = iv_search_string
            io_tech_request_context  = io_tech_request_context
          IMPORTING
            er_entityset             = er_entityset
            es_response_context      = es_response_context ).
    ENDCASE.

  ENDMETHOD.


  METHOD filter_value.
*   The property name arrives as the model name ('So') or the ABAP field
*   name ('SO') depending on which context parsed the filter; the two
*   spellings differ only in case for every property here.
    LOOP AT it_filter INTO DATA(ls_f).
      IF to_upper( ls_f-property ) = to_upper( iv_property ).
        READ TABLE ls_f-select_options INTO DATA(ls_so) INDEX 1.
        IF sy-subrc = 0.
          rv_value = ls_so-low.
        ENDIF.
        EXIT.
      ENDIF.
    ENDLOOP.
    CONDENSE rv_value.
  ENDMETHOD.


  METHOD clean.
    rv_text = iv_text.
    REPLACE ALL OCCURRENCES OF '|' IN rv_text WITH '/'.
    REPLACE ALL OCCURRENCES OF ';' IN rv_text WITH ','.
  ENDMETHOD.


  METHOD get_packing_lists.

    TYPES: BEGIN OF ty_agg,
             vbeln     TYPE vbeln_va,
             posnr     TYPE posnr_va,
             pklst     TYPE zpp_pack-pklst,
             box_count TYPE i,
             netwt     TYPE zpp_pack-netwt,
             pldate    TYPE zpp_pack-pldate,
             werks     TYPE werks_d,
             matnr     TYPE matnr,
             max_pdate TYPE zpp_pack-pdate,
           END OF ty_agg.
    TYPES: BEGIN OF ty_loaded,
             vbeln  TYPE vbeln_va,
             posnr  TYPE posnr_va,
             pklst  TYPE zpp_pack-pklst,
             loaded TYPE i,
           END OF ty_loaded.

    DATA: lt_agg    TYPE STANDARD TABLE OF ty_agg,
          lt_loaded TYPE SORTED TABLE OF ty_loaded WITH UNIQUE KEY vbeln posnr pklst,
          ls_loaded TYPE ty_loaded,
          lr_werks  TYPE zcl_zsol_app_auth=>ty_r_werks,
          lr_vbeln  TYPE RANGE OF vbeln_va,
          lv_vbeln  TYPE vbeln_va,
          lv_mode   TYPE zcl_zsol_challan_pack__mpc_ext=>ts_packinglist-mode.

*   Which screen is asking. Anything but the two known modes is a
*   programming error on the client, reported rather than treated as
*   "all".
    lv_mode = to_upper( iv_mode ).
    IF lv_mode IS NOT INITIAL AND lv_mode <> 'LOAD' AND lv_mode <> 'CHALLAN'.
      RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
        EXPORTING
          textid  = /iwbep/cx_mgw_busi_exception=>business_error
          message = |Mode { iv_mode } is not LOAD or CHALLAN|.
    ENDIF.

    lr_werks = zcl_zsol_app_auth=>allowed_plants( is_session-orgs ).

    IF iv_so IS NOT INITIAL.
      lv_vbeln = |{ iv_so ALPHA = IN }|.
      zcl_zsol_app_auth=>require_sales_order( it_orgs  = is_session-orgs
                                              iv_vbeln = lv_vbeln ).
      APPEND VALUE #( sign = 'I' option = 'EQ' low = lv_vbeln ) TO lr_vbeln.
    ENDIF.

*   Same "pending" rule as the two string-encoded reads below (live HU not
*   on a delivery, on a packing list, no Challan-log row since the list
*   was made), grouped by packing list. EXISTS rather than a join so a
*   split HU cannot double the weight.
    SELECT p~vbeln, p~posnr, p~pklst,
           COUNT( DISTINCT p~boxno ) AS box_count,
           SUM( p~netwt )            AS netwt,
           MIN( p~pldate )           AS pldate,
           MAX( p~werks )            AS werks,
           MAX( p~matnr )            AS matnr,
           MAX( p~pdate )            AS max_pdate
      FROM zpp_pack AS p
      WHERE p~exidv <> @space
        AND p~vbeln <> @space
        AND p~pklst <> @space
        AND p~pldel  = @space
        AND p~werks IN @lr_werks
        AND p~vbeln IN @lr_vbeln
        AND EXISTS ( SELECT venum FROM vekp AS v
                       WHERE v~exidv  = p~exidv
                         AND v~status IN ( '0020', '0030' )
                         AND v~vpobj  IN ( '00', '06', '12' ) )
        AND NOT EXISTS ( SELECT boxno FROM zsol_challan_log AS lg
                           WHERE lg~boxno = p~boxno
                             AND lg~vbeln = p~vbeln
                             AND lg~posnr = p~posnr
                             AND lg~erdat >= p~pldate )
      GROUP BY p~vbeln, p~posnr, p~pklst
      ORDER BY max_pdate DESCENDING, p~vbeln, p~posnr, p~pklst
      INTO TABLE @lt_agg
      UP TO 400 ROWS.

    IF lt_agg IS INITIAL.
      RETURN.
    ENDIF.

*   Of those pending cartons, the ones Security has confirmed - the rule
*   in the class comment: a ZSOL_HUDISPATCH row for the box, not 'E-',
*   for this packing list, dated on or after the list. Same pending
*   conditions again so a confirmed carton that has since gone onto a
*   challan is not counted twice over.
    SELECT p~vbeln, p~posnr, p~pklst,
           COUNT( DISTINCT p~boxno ) AS loaded
      FROM zpp_pack AS p
      INNER JOIN zsol_hudispatch AS hd ON hd~boxno = p~boxno
      WHERE p~exidv <> @space
        AND p~vbeln <> @space
        AND p~pklst <> @space
        AND p~pldel  = @space
        AND p~werks IN @lr_werks
        AND p~vbeln IN @lr_vbeln
        AND hd~status <> 'E-'
        AND hd~pck_lst = p~pklst
        AND hd~erdat  >= p~pldate
        AND EXISTS ( SELECT venum FROM vekp AS v
                       WHERE v~exidv  = p~exidv
                         AND v~status IN ( '0020', '0030' )
                         AND v~vpobj  IN ( '00', '06', '12' ) )
        AND NOT EXISTS ( SELECT boxno FROM zsol_challan_log AS lg
                           WHERE lg~boxno = p~boxno
                             AND lg~vbeln = p~vbeln
                             AND lg~posnr = p~posnr
                             AND lg~erdat >= p~pldate )
      GROUP BY p~vbeln, p~posnr, p~pklst
      INTO TABLE @lt_loaded.

*   Names for the list: material text and sold-to.
    SELECT a~vbeln, a~kunnr, k~name1
      FROM vbak AS a
      LEFT OUTER JOIN kna1 AS k ON k~kunnr = a~kunnr
      FOR ALL ENTRIES IN @lt_agg
      WHERE a~vbeln = @lt_agg-vbeln
      INTO TABLE @DATA(lt_cust).
    SORT lt_cust BY vbeln.

    SELECT matnr, maktx FROM makt
      FOR ALL ENTRIES IN @lt_agg
      WHERE matnr = @lt_agg-matnr
        AND spras = @sy-langu
      INTO TABLE @DATA(lt_makt).
    SORT lt_makt BY matnr.

    LOOP AT lt_agg INTO DATA(ls_agg).
      READ TABLE lt_loaded INTO ls_loaded
        WITH TABLE KEY vbeln = ls_agg-vbeln posnr = ls_agg-posnr pklst = ls_agg-pklst.
      IF sy-subrc <> 0.
        CLEAR ls_loaded.
      ENDIF.

*     The mode decides which lists the screen sees. LOAD: something left
*     for Security to confirm. CHALLAN: something confirmed to make a
*     challan of. No mode: everything pending.
      CASE lv_mode.
        WHEN 'LOAD'.
          CHECK ls_loaded-loaded < ls_agg-box_count.
        WHEN 'CHALLAN'.
          CHECK ls_loaded-loaded > 0.
      ENDCASE.

      APPEND INITIAL LINE TO rt_list ASSIGNING FIELD-SYMBOL(<ls_out>).
      <ls_out>-so          = ls_agg-vbeln.
      <ls_out>-soitem      = ls_agg-posnr.
      <ls_out>-pklst       = ls_agg-pklst.
      <ls_out>-pldate      = ls_agg-pldate.
      <ls_out>-boxcount    = ls_agg-box_count.
      <ls_out>-loadedcount = ls_loaded-loaded.
      <ls_out>-netwt       = ls_agg-netwt.
      <ls_out>-plant       = ls_agg-werks.
      <ls_out>-material    = ls_agg-matnr.
      <ls_out>-mode        = lv_mode.
      READ TABLE lt_makt INTO DATA(ls_makt) WITH KEY matnr = ls_agg-matnr BINARY SEARCH.
      IF sy-subrc = 0.
        <ls_out>-matdesc = ls_makt-maktx.
      ENDIF.
      READ TABLE lt_cust INTO DATA(ls_cust) WITH KEY vbeln = ls_agg-vbeln BINARY SEARCH.
      IF sy-subrc = 0.
        <ls_out>-customer = ls_cust-kunnr.
        <ls_out>-custname = ls_cust-name1.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.


  METHOD get_packing_list_boxes.

    DATA: lv_vbeln TYPE vbeln_va,
          lv_posnr TYPE posnr_va,
          lv_pklst TYPE zpp_pack-pklst.

    IF iv_so IS INITIAL OR iv_soitem IS INITIAL OR iv_pklst IS INITIAL.
      RETURN.
    ENDIF.

    lv_vbeln = |{ iv_so ALPHA = IN }|.
    lv_posnr = |{ iv_soitem ALPHA = IN }|.
    lv_pklst = |{ iv_pklst ALPHA = IN }|.

    zcl_zsol_app_auth=>require_sales_order( it_orgs  = is_session-orgs
                                            iv_vbeln = lv_vbeln ).

    SELECT DISTINCT p~boxno, p~vbeln, p~posnr, p~pklst, p~pldate, p~exidv, p~ptype,
                    p~netwt, p~mergno, v~status
      FROM zpp_pack AS p
      INNER JOIN vekp AS v ON v~exidv = p~exidv
      WHERE p~vbeln = @lv_vbeln
        AND p~posnr = @lv_posnr
        AND p~pklst = @lv_pklst
        AND p~pldel = @space
        AND p~exidv <> @space
        AND v~status IN ( '0020', '0030' )
        AND v~vpobj  IN ( '00', '06', '12' )
        AND NOT EXISTS ( SELECT boxno FROM zsol_challan_log AS lg
                           WHERE lg~boxno = p~boxno
                             AND lg~vbeln = p~vbeln
                             AND lg~posnr = p~posnr
                             AND lg~erdat >= p~pldate )
      ORDER BY p~boxno
      INTO TABLE @DATA(lt_box).

    IF lt_box IS INITIAL.
      RETURN.
    ENDIF.

    SELECT ptype, pkdes FROM zpp_ptyp INTO TABLE @DATA(lt_ptyp).
    SORT lt_ptyp BY ptype.

*   Security's scan of each carton, if any. One row per box number in
*   ZSOL_HUDISPATCH; whether it counts as a confirmation of THIS list is
*   decided below, by the rule in the class comment.
    SELECT boxno, pck_lst, erdat, time, status
      FROM zsol_hudispatch
      FOR ALL ENTRIES IN @lt_box
      WHERE boxno = @lt_box-boxno
      INTO TABLE @DATA(lt_disp).
    SORT lt_disp BY boxno.

    LOOP AT lt_box INTO DATA(ls_box).
      APPEND INITIAL LINE TO rt_boxes ASSIGNING FIELD-SYMBOL(<ls_out>).
      <ls_out>-boxno    = ls_box-boxno.
      <ls_out>-so       = ls_box-vbeln.
      <ls_out>-soitem   = ls_box-posnr.
      <ls_out>-pklst    = ls_box-pklst.
      <ls_out>-exidv    = ls_box-exidv.
      <ls_out>-ptype    = ls_box-ptype.
      <ls_out>-netwt    = ls_box-netwt.
      <ls_out>-mergno   = ls_box-mergno.
      <ls_out>-hustatus = ls_box-status.
      READ TABLE lt_ptyp INTO DATA(ls_ptyp) WITH KEY ptype = ls_box-ptype BINARY SEARCH.
      IF sy-subrc = 0.
        <ls_out>-ptypetext = ls_ptyp-pkdes.
      ENDIF.
      READ TABLE lt_disp INTO DATA(ls_disp) WITH KEY boxno = ls_box-boxno BINARY SEARCH.
      IF sy-subrc = 0
         AND ls_disp-status  <> 'E-'
         AND ls_disp-pck_lst  = ls_box-pklst
         AND ls_disp-erdat   >= ls_box-pldate.
        <ls_out>-loaded   = abap_true.
        <ls_out>-loaddate = ls_disp-erdat.
        <ls_out>-loadtime = ls_disp-time.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.


  METHOD get_trucks.

    SELECT t~zztrckno AS trckno, t~zztrcode AS trcode, m~zztrdesc AS trname
      FROM ztrckmstr AS t
      LEFT OUTER JOIN ztrptmstr AS m ON m~zztrcode = t~zztrcode
      WHERE t~zztrckno <> @space
      ORDER BY t~zztrckno
      INTO CORRESPONDING FIELDS OF TABLE @rt_trucks.

  ENDMETHOD.


  METHOD create_challan.

    DATA: lt_fields TYPE TABLE OF string,
          lv_vbeln  TYPE vbeln_va,
          lv_posnr  TYPE posnr_va,
          lv_pklst  TYPE zpp_pack-pklst,
          lv_wadat  TYPE likp-wadat_ist,
          lv_trcode TYPE likp-zztrcode,
          lv_trckno TYPE likp-zztrckno,
          lv_gidate TYPE string,
          lv_box    TYPE string,
          lv_so     TYPE string.

*   "So|SoItem|Pklst|GiDate|Trcode|Trckno" - the last three may be empty.
    SPLIT iv_boxdata AT '|' INTO TABLE lt_fields.
    IF lines( lt_fields ) < 3.
      RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
        EXPORTING
          textid  = /iwbep/cx_mgw_busi_exception=>business_error
          message = 'Create Challan needs sales order, item and packing list'.
    ENDIF.

    lv_vbeln = |{ condense( lt_fields[ 1 ] ) ALPHA = IN }|.
    lv_posnr = |{ condense( lt_fields[ 2 ] ) ALPHA = IN }|.
    lv_pklst = |{ condense( lt_fields[ 3 ] ) ALPHA = IN }|.

*   Goods issue date, YYYYMMDD. Left initial when blank - the posting
*   class then takes today, exactly as ZSDOBDN defaults its date field.
    IF lines( lt_fields ) >= 4.
      lv_gidate = condense( lt_fields[ 4 ] ).
      IF lv_gidate IS NOT INITIAL.
        IF strlen( lv_gidate ) <> 8 OR lv_gidate CN '0123456789'.
          RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
            EXPORTING
              textid  = /iwbep/cx_mgw_busi_exception=>business_error
              message = |Goods issue date { lv_gidate } is not a date (YYYYMMDD)|.
        ENDIF.
        lv_wadat = lv_gidate.
        CALL FUNCTION 'DATE_CHECK_PLAUSIBILITY'
          EXPORTING
            date                      = lv_wadat
          EXCEPTIONS
            plausibility_check_failed = 1
            OTHERS                    = 2.
        IF sy-subrc <> 0.
          RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
            EXPORTING
              textid  = /iwbep/cx_mgw_busi_exception=>business_error
              message = |Goods issue date { lv_gidate } is not a valid date|.
        ENDIF.
      ENDIF.
    ENDIF.
    IF lines( lt_fields ) >= 5.
      lv_trcode = to_upper( condense( lt_fields[ 5 ] ) ).
    ENDIF.
    IF lines( lt_fields ) >= 6.
      lv_trckno = to_upper( condense( lt_fields[ 6 ] ) ).
    ENDIF.

    IF lv_vbeln IS INITIAL OR lv_posnr IS INITIAL OR lv_pklst IS INITIAL.
      RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
        EXPORTING
          textid  = /iwbep/cx_mgw_busi_exception=>business_error
          message = 'Create Challan needs sales order, item and packing list'.
    ENDIF.

*   The order must be one the caller may act on. Checked before anything
*   posts.
    zcl_zsol_app_auth=>require_sales_order( it_orgs  = is_session-orgs
                                            iv_vbeln = lv_vbeln ).

*   A truck, if given, must be a known one; its transporter is taken from
*   the master unless the app sent one explicitly.
    IF lv_trckno IS NOT INITIAL.
      SELECT SINGLE zztrcode FROM ztrckmstr
        WHERE zztrckno = @lv_trckno
        INTO @DATA(lv_master_code).
      IF sy-subrc <> 0.
        RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
          EXPORTING
            textid  = /iwbep/cx_mgw_busi_exception=>business_error
            message = |Truck { lv_trckno } is not in the truck master|.
      ENDIF.
      IF lv_trcode IS INITIAL.
        lv_trcode = lv_master_code.
      ENDIF.
    ENDIF.

*   Only the cartons Security has confirmed go onto the delivery
*   (IV_LOADED_ONLY defaults to true) - see the class comment.
    DATA(lo_obd) = NEW zcl_zsol_obd_create( ).
    DATA(ls_res) = lo_obd->create_for_packing_list( iv_vbeln  = lv_vbeln
                                                    iv_posnr  = lv_posnr
                                                    iv_pklst  = lv_pklst
                                                    iv_wadat  = lv_wadat
                                                    iv_trcode = lv_trcode
                                                    iv_trckno = lv_trckno ).

*   Response. BoxData: the verdict, then the deliveries.
    cs_entity-app     = 'D'.
    cs_entity-boxdata = |R\|{ ls_res-type }\|{ clean( ls_res-message ) };|.
    LOOP AT ls_res-deliveries INTO DATA(ls_d).
      cs_entity-boxdata = cs_entity-boxdata &&
        |D\|{ ls_d-deliv_numb ALPHA = OUT }\|{ ls_d-type }\|{ clean( ls_d-message ) };|.
    ENDLOOP.

*   SoItemList: every carton, then the message trail while it fits.
    CLEAR cs_entity-soitemlist.
    LOOP AT ls_res-boxes INTO DATA(ls_b).
      lv_box = |B\|{ ls_b-boxno }\|{ ls_b-type }\|{ clean( ls_b-message ) };|.
      IF strlen( cs_entity-soitemlist ) + strlen( lv_box ) > 7900.
        EXIT.
      ENDIF.
      cs_entity-soitemlist = cs_entity-soitemlist && lv_box.
    ENDLOOP.
    LOOP AT ls_res-log INTO DATA(lv_line).
      lv_so = |L\|{ clean( lv_line ) };|.
      IF strlen( cs_entity-soitemlist ) + strlen( lv_so ) > 7900.
        EXIT.
      ENDIF.
      cs_entity-soitemlist = cs_entity-soitemlist && lv_so.
    ENDLOOP.

  ENDMETHOD.


  METHOD challanpackset_create_entity.

    DATA: ls_entity   TYPE zcl_zsol_challan_pack__mpc=>ts_challanpack,
          lt_boxes_in TYPE zcl_zsol_challan_pack=>tt_box_input,
          lt_result   TYPE zcl_zsol_challan_pack=>tt_challan_result,
          lo_pack     TYPE REF TO zcl_zsol_challan_pack,
          lt_lines    TYPE TABLE OF string,
          lt_fields   TYPE TABLE OF string,
          lt_so_seen  TYPE STANDARD TABLE OF vbeln_va WITH EMPTY KEY,
          lt_malformed TYPE STANDARD TABLE OF string WITH EMPTY KEY,
          lv_vbeln    TYPE vbeln_va.

    DATA(ls_session) = zcl_zsol_app_auth=>check_request(
      it_header  = io_tech_request_context->get_request_headers( )
      iv_feature = 'CHALLAN' ).

    IF io_data_provider IS NOT BOUND.
      RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
        EXPORTING
          textid  = /iwbep/cx_mgw_busi_exception=>business_error
          message = 'No boxes supplied for Create Challan'.
    ENDIF.

    io_data_provider->read_entry_data( IMPORTING es_data = ls_entity ).

*   App = 'D': the real challan for one packing list (06.09.2026).
    IF ls_entity-app = 'D'.
      create_challan( EXPORTING is_session = ls_session
                                iv_boxdata = CONV #( ls_entity-boxdata )
                      CHANGING  cs_entity  = ls_entity ).
      er_entity = ls_entity.
      RETURN.
    ENDIF.

*   App = 'X': the per-box log, unchanged - still used by the Android
*   scanner.
    SPLIT ls_entity-boxdata AT ';' INTO TABLE lt_lines.

    LOOP AT lt_lines INTO DATA(lv_line).
      CHECK lv_line IS NOT INITIAL.
      SPLIT lv_line AT '|' INTO TABLE lt_fields.
      IF lines( lt_fields ) = 3.
        APPEND VALUE #( boxno = lt_fields[ 1 ]
                         vbeln = lt_fields[ 2 ]
                         posnr = lt_fields[ 3 ] ) TO lt_boxes_in.
      ELSE.
*       A line that does not split into boxno|order|item is not packed. It
*       is collected and reported back in the result with an error type,
*       the same way a genuine pack failure is. (L1, 2026-09-03)
        APPEND lv_line TO lt_malformed.
      ENDIF.
    ENDLOOP.

    IF lt_boxes_in IS INITIAL AND lt_malformed IS INITIAL.
      RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
        EXPORTING
          textid  = /iwbep/cx_mgw_busi_exception=>business_error
          message = 'No boxes supplied for Create Challan'.
    ENDIF.

*   This is a real posting - it flags the boxes onto their existing
*   delivery - so every order named in the payload has to be one the
*   caller may act on. Checked once per distinct order, before anything is
*   packed - a partial refusal halfway through would leave some boxes
*   flagged and some not.
    LOOP AT lt_boxes_in INTO DATA(ls_box_chk).
      lv_vbeln = |{ ls_box_chk-vbeln ALPHA = IN }|.
      CHECK lv_vbeln IS NOT INITIAL.
      READ TABLE lt_so_seen TRANSPORTING NO FIELDS WITH KEY table_line = lv_vbeln.
      CHECK sy-subrc <> 0.
      APPEND lv_vbeln TO lt_so_seen.
      zcl_zsol_app_auth=>require_sales_order( it_orgs  = ls_session-orgs
                                              iv_vbeln = lv_vbeln ).
    ENDLOOP.

    IF lt_boxes_in IS NOT INITIAL.
      CREATE OBJECT lo_pack.
      lo_pack->pack_boxes( EXPORTING it_boxes  = lt_boxes_in
                            IMPORTING et_result = lt_result ).
    ENDIF.

    CLEAR ls_entity-boxdata.
    LOOP AT lt_result INTO DATA(ls_res).
      ls_entity-boxdata = ls_entity-boxdata &&
        ls_res-boxno && '|' && ls_res-type && '|' && ls_res-message &&
        COND #( WHEN ls_res-deliv_numb IS NOT INITIAL
                THEN | (Delivery { ls_res-deliv_numb })|
                ELSE || ) && ';'.
    ENDLOOP.

*   Malformed lines are reported after the packed ones, so nothing the app
*   sent is silently lost. (L1, 2026-09-03)
    LOOP AT lt_malformed INTO DATA(lv_bad).
      ls_entity-boxdata = ls_entity-boxdata &&
        lv_bad && '|E|Ignored - not in boxno|order|item format;'.
    ENDLOOP.

    ls_entity-app = 'X'.

    er_entity = ls_entity.

  ENDMETHOD.


  METHOD challanpackset_get_entityset.

    TYPES: BEGIN OF ty_so_item,
             vbeln     TYPE vbeln_va,
             posnr     TYPE posnr_va,
             box_count TYPE i,
             max_pdate TYPE zpp_pack-pdate,
           END OF ty_so_item.
    TYPES: BEGIN OF ty_deliv,
             deliv_key  TYPE vpobjkey,    " VEKP-VPOBJKEY: delivery number in the first 10 characters
             box_count  TYPE i,
             max_aedat  TYPE vekp-aedat,
           END OF ty_deliv.

    DATA: ls_entity     TYPE zcl_zsol_challan_pack__mpc=>ts_challanpack,
          lt_so_item    TYPE TABLE OF ty_so_item,
          lt_deliv      TYPE TABLE OF ty_deliv,
          lr_werks      TYPE zcl_zsol_app_auth=>ty_r_werks,
          lv_soitemlist TYPE string,
          lv_boxdata    TYPE string,
          lv_since      TYPE vekp-aedat.

    DATA(ls_session) = zcl_zsol_app_auth=>check_request(
      io_tech_request_context->get_request_headers( ) ).

*   The caller's plants, as a range. Empty for a session with no grants -
*   the ISCAN_APP service user - and an empty range restricts nothing, so
*   that app sees exactly what it saw before.
    lr_werks = zcl_zsol_app_auth=>allowed_plants( ls_session-orgs ).

*   ---- SoItemList: SO/Items with boxes packed (scanned) but not yet assigned to a Challan ----
*   Kept for the Android scanner; the Scan Suite's Create Challan now reads
*   PackingListSet. Field is limited to 8000 chars (~350 entries) - most
*   recently packed shown first. Same pending rule as PackingListSet.
    SELECT p~vbeln, p~posnr,
           COUNT( DISTINCT p~boxno ) AS box_count,
           MAX( p~pdate ) AS max_pdate
      FROM zpp_pack AS p
      INNER JOIN vekp AS v
        ON v~exidv = p~exidv
      WHERE p~exidv  <> @space
        AND p~vbeln  <> @space
        AND p~pklst  <> @space
        AND p~werks  IN @lr_werks
        AND v~status IN ( '0020', '0030' )
        AND v~vpobj  IN ( '00', '06', '12' )
        AND NOT EXISTS ( SELECT boxno FROM zsol_challan_log AS lg
                            WHERE lg~boxno = p~boxno
                              AND lg~vbeln = p~vbeln
                              AND lg~posnr = p~posnr
                              AND lg~erdat >= p~pldate )
      GROUP BY p~vbeln, p~posnr
      ORDER BY max_pdate DESCENDING
      INTO TABLE @lt_so_item
      UP TO 350 ROWS.

    LOOP AT lt_so_item INTO DATA(ls_so_item).
      lv_soitemlist = lv_soitemlist &&
        ls_so_item-vbeln && '|' && ls_so_item-posnr && '|' && ls_so_item-box_count && ';'.
    ENDLOOP.

*   ---- BoxData: Deliveries (Challans) pending Security Loading confirmation ----
*   Kept for the Android scanner (07.09.2026): the Scan Suite's Security
*   Loading Scan now reads PackingListSet with Mode eq 'LOAD', because
*   Security confirms BEFORE the challan exists.
*
*   Field is limited to 1000 chars (~60 entries) - newest first, so today's
*   Challans are always inside the cap.
*
*   Source is VEKP (05.09.2026): every HU packed onto a delivery, whichever
*   process created the delivery. ZPP_PACK supplies the 10-digit box
*   number the dispatch table is keyed on, and the plant - VEKP-WERKS is
*   blank on delivery HUs.
*
*   STATUS 0050 IS IN (06.09.2026). A challan made by ZSDOBDN or by the
*   app's Create Challan has its goods issue posted at creation, so its
*   HUs are 0050 from the first second and the old 0020/0030 test never
*   showed them. GI-posted deliveries count when the HU was changed in the
*   last 30 days and the delivery is not fully billed (LIKP-FKSTK <> 'C',
*   the invoice being the step after Security Loading). 0020/0030 stay in
*   unchanged for deliveries still waiting for goods issue.
*
*   THE DISPATCH MATCH IS ON BOX + TIME, NOT BOX ALONE (03.09.2026): a
*   dispatch row only clears a box if it is stamped at or after the HU's
*   last change, which packing into the delivery (and the goods issue)
*   sets. COUNT( DISTINCT boxno ): EXIDV is not VEKP's primary key.
    lv_since = sy-datum - 30.

    SELECT v~vpobjkey AS deliv_key,
           COUNT( DISTINCT p~boxno ) AS box_count,
           MAX( v~aedat ) AS max_aedat
      FROM vekp AS v
      INNER JOIN zpp_pack AS p
        ON p~exidv = v~exidv
      INNER JOIN likp AS l
        ON l~vbeln = substring( v~vpobjkey, 1, 10 )
      WHERE v~vpobj  = '01'
        AND p~werks  IN @lr_werks
        AND ( v~status IN ( '0020', '0030' )
           OR ( v~status = '0050' AND v~aedat >= @lv_since AND l~fkstk <> 'C' ) )
        AND NOT EXISTS ( SELECT boxno FROM zsol_hudispatch AS hd
                            WHERE hd~boxno = p~boxno
                              AND ( hd~erdat > v~aedat
                                 OR ( hd~erdat = v~aedat
                                  AND hd~time >= v~aezet ) ) )
      GROUP BY v~vpobjkey
      ORDER BY max_aedat DESCENDING
      INTO TABLE @lt_deliv
      UP TO 60 ROWS.

*   VPOBJKEY is CHAR20; the delivery number is its first ten characters,
*   which is the form the app sends back on the manual path as well.
    LOOP AT lt_deliv INTO DATA(ls_deliv).
      lv_boxdata = lv_boxdata &&
        ls_deliv-deliv_key(10) && '|' && ls_deliv-box_count && ';'.
    ENDLOOP.

    ls_entity-app        = 'X'.
    ls_entity-soitemlist = lv_soitemlist.
    ls_entity-boxdata    = lv_boxdata.

    APPEND ls_entity TO et_entityset.

  ENDMETHOD.


  METHOD challanpackboxse_get_entityset.

*   Given ?$filter=So eq '<vbeln>' and SoItem eq '<posnr>', returns every
*   box (from ZPP_PACK) still pending pack (live HU, on a packing list,
*   not yet on a Challan) for that Sales Order/Item. Kept for the Android
*   scanner; the Scan Suite reads PackingListBoxSet.

    TYPES: BEGIN OF ty_box,
             boxno TYPE zpp_pack-boxno,
             vbeln TYPE vbeln_va,
             posnr TYPE posnr_va,
           END OF ty_box.

    DATA: lv_so     TYPE vbeln_va,
          lv_soitem TYPE posnr_va,
          lv_vbeln  TYPE vbeln_va,
          ls_box    TYPE zcl_zsol_challan_pack__mpc=>ts_challanpackbox,
          lt_pack   TYPE TABLE OF ty_box.

    DATA(ls_session) = zcl_zsol_app_auth=>check_request(
      io_tech_request_context->get_request_headers( ) ).

    FIND PCRE `So eq '([^']*)'` IN iv_filter_string SUBMATCHES lv_so.
    FIND PCRE `SoItem eq '([^']*)'` IN iv_filter_string SUBMATCHES lv_soitem.

    IF lv_so IS INITIAL OR lv_soitem IS INITIAL.
      RETURN.
    ENDIF.

*   The order number comes out of the filter string in whatever format
*   the app sent it; the access check needs the internal one, and so does
*   the read.
    lv_vbeln = |{ lv_so ALPHA = IN }|.

    zcl_zsol_app_auth=>require_sales_order( it_orgs  = ls_session-orgs
                                            iv_vbeln = lv_vbeln ).

    SELECT DISTINCT p~boxno, p~vbeln, p~posnr
      FROM zpp_pack AS p
      INNER JOIN vekp AS v
        ON v~exidv = p~exidv
      WHERE p~exidv  <> @space
        AND p~vbeln  = @lv_vbeln
        AND p~posnr  = @lv_soitem
        AND p~pklst  <> @space
        AND v~status IN ( '0020', '0030' )
        AND v~vpobj  IN ( '00', '06', '12' )
        AND NOT EXISTS ( SELECT boxno FROM zsol_challan_log AS lg
                            WHERE lg~boxno = p~boxno
                              AND lg~vbeln = p~vbeln
                              AND lg~posnr = p~posnr
                              AND lg~erdat >= p~pldate )
      ORDER BY p~boxno
      INTO TABLE @lt_pack.

    LOOP AT lt_pack INTO DATA(ls_pack).
      CLEAR ls_box.
      ls_box-boxno  = ls_pack-boxno.
      ls_box-so     = ls_pack-vbeln.
      ls_box-soitem = ls_pack-posnr.
      APPEND ls_box TO et_entityset.
    ENDLOOP.

  ENDMETHOD.

ENDCLASS.
