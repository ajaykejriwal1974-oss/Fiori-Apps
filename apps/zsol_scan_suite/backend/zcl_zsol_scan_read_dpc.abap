class ZCL_ZSOL_SCAN_READ_DPC definition
  public
  inheriting from /IWBEP/CL_MGW_PUSH_ABS_DATA
  create public .

public section.

* ----------------------------------------------------------------------
* Scan Suite - guarded replacements for four CDS-published services.
* See ZCL_ZSOL_SCAN_READ_MPC for why this service exists.
*
* Every read here demands a valid app session, exactly as the seven SEGW
* services already do. The check is session-only rather than per-feature
* because three of these four sets are shared between two screens - the
* inventory sets by Count and Reconcile, the packing list by Packing List
* and Dispatch - and a feature check would refuse somebody who has been
* granted one screen but not the other. Writes are unaffected: they still
* go through the guarded services, which do check the feature.
*
* CHECK_REQUEST returns the caller's granted company codes and plants,
* and ALL FOUR sets now use them. The first pass on 01.09.2026 only did
* two - the pending orders and the inventory headers - and left the other
* two keyed on a value the caller supplies and nobody checked:
*
*   ZSOL_PLIST needed a sales order, and then returned any order's boxes.
*   Of 1,976 rows across six company codes, an operator granted only
*   1000/1000 could read 1,825 of them.
*
*   ZSOL_HUINV_ITM_PUSH needed a count document, and then returned any
*   document's items - including document 9000000016, which is 9,594
*   counted handling units in plant 6000. The header set two branches
*   above was already filtered to the caller's plants, which made this
*   the more conspicuous: the list of documents was scoped, and the
*   contents of any document you could name were not.
*
* ZSOL_RESERVATION (06.09.2026) is the fifth set: open manual
* reservations for the HU Movement screen's dropdown, read from
* RESB/RKPF and scoped to the caller's plants on either side of the
* transfer.
*
* ZSOL_SO_BOXCHECK and ZSOL_SO_BATCH (06.09.2026): why the Packing List
* offers no boxes for an order, and the batches the order names. The
* second is the one set here that is written: CREATE_ENTITY assigns a
* batch to an item, DELETE_ENTITY removes one, both only for a caller
* holding the SOCHG screen and the order's company code / plants. The
* rules and the ZVBAP_BATCH writes live in ZCL_ZSOL_SO_BOXCHECK.
*
* This class is hand-written rather than SEGW-generated, so it is safe to
* edit directly - there is no base class that regeneration would
* overwrite, and no _EXT subclass.
* ----------------------------------------------------------------------

  methods /IWBEP/IF_MGW_APPL_SRV_RUNTIME~GET_ENTITYSET
    redefinition .
  methods /IWBEP/IF_MGW_APPL_SRV_RUNTIME~CREATE_ENTITY
    redefinition .
  methods /IWBEP/IF_MGW_APPL_SRV_RUNTIME~DELETE_ENTITY
    redefinition .

protected section.

  methods CHECK_SUBSCRIPTION_AUTHORITY
    redefinition .

private section.

* A select-option range the ABAP SQL WHERE clause can consume directly.
* An empty range means "no restriction" - which is exactly the behaviour
* wanted when the caller sends no $filter at all, so an unfiltered call
* keeps working unchanged.
  types:
    begin of TS_DATE_RANGE,
      sign   type c length 1,
      option type c length 2,
      low    type d,
      high   type d,
    end of TS_DATE_RANGE .
  types:
    TT_DATE_RANGE type standard table of TS_DATE_RANGE with empty key .

  types:
    begin of TS_BUKRS_RANGE,
      sign   type c length 1,
      option type c length 2,
      low    type bukrs,
      high   type bukrs,
    end of TS_BUKRS_RANGE .
  types:
    TT_BUKRS_RANGE type standard table of TS_BUKRS_RANGE with empty key .

* The pending set is read into this rather than straight into the model
* structure, because BUKRS and WERKS are needed to decide what the caller
* may see but are not part of what the app is told.
  types:
    begin of TS_PEND_INT,
      ship_point  type c length 4,
      vbeln       type c length 10,
      posnr       type c length 6,
      shipto      type c length 10,
      shiptoparty type c length 35,
      soldto      type c length 10,
      soldtoparty type c length 35,
      deliv_date  type c length 8,
      created_on  type c length 8,
      bukrs       type bukrs,
      werks       type werks_d,
    end of TS_PEND_INT .
  types:
    TT_PEND_INT type standard table of TS_PEND_INT with empty key .

  methods FILTER_VALUE
    importing
      IT_FILTER type /IWBEP/T_MGW_SELECT_OPTION
      IV_PROPERTY type STRING
    returning
      value(RV_VALUE) type STRING .

  methods FILTER_DATE_RANGE
    importing
      IT_FILTER type /IWBEP/T_MGW_SELECT_OPTION
      IV_PROPERTY type STRING
    returning
      value(RT_RANGE) type TT_DATE_RANGE .

  methods FAIL
    importing
      IV_MESSAGE type STRING
    raising
      /IWBEP/CX_MGW_BUSI_EXCEPTION .

  methods APPLY_PAGING
    importing
      IS_PAGING type /IWBEP/S_MGW_PAGING
    changing
      CT_DATA type STANDARD TABLE .

* ZCL_ZSOL_SO_BOXCHECK rows -> the model's all-string rows.
  methods CHECK_TO_ROWS
    importing
      IT_ITEMS type ZCL_ZSOL_SO_BOXCHECK=>TT_ITEM
    returning
      value(RT_ROWS) type ZCL_ZSOL_SCAN_READ_MPC=>TT_SO_CHECK .

* Key value of a POST/DELETE, from the key table or the payload.
  methods KEY_VALUE
    importing
      IT_KEY_TAB type /IWBEP/T_MGW_NAME_VALUE_PAIR
      IV_NAME type STRING
    returning
      value(RV_VALUE) type STRING .

ENDCLASS.



CLASS ZCL_ZSOL_SCAN_READ_DPC IMPLEMENTATION.


  METHOD check_subscription_authority.

    " Nothing subscribes to this service; the parent declares the method
    " so it has to be implemented.
    RETURN.

  ENDMETHOD.


  METHOD fail.

    " Same shape of refusal the rest of the suite produces, so a message
    " from here reads like every other one on the handheld.
    DATA lv_msg TYPE c LENGTH 220.

    lv_msg = iv_message.

    RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
      EXPORTING
        textid  = /iwbep/cx_mgw_busi_exception=>business_error
        message = lv_msg.

  ENDMETHOD.


  METHOD filter_value.

    " Reads the single value behind "$filter=<property> eq '<value>'".
    " The app only ever sends that one shape; anything more elaborate is
    " ignored rather than half-honoured, which would silently return the
    " wrong rows.
    DATA lv_prop TYPE string.

    FIELD-SYMBOLS <ls_filter> TYPE /iwbep/s_mgw_select_option.

    LOOP AT it_filter ASSIGNING <ls_filter>.
      lv_prop = <ls_filter>-property.
      TRANSLATE lv_prop TO UPPER CASE.
      IF lv_prop = to_upper( iv_property ).
        READ TABLE <ls_filter>-select_options ASSIGNING FIELD-SYMBOL(<ls_opt>) INDEX 1.
        IF sy-subrc = 0.
          rv_value = <ls_opt>-low.
        ENDIF.
        RETURN.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.


  METHOD filter_date_range.

    " The range counterpart of FILTER_VALUE. Gateway has already parsed
    " "created_on ge '20260101' and created_on le '20260930'" into one
    " select-option with OPTION = 'BT', so the whole shape - EQ, GE, LE,
    " BT, several at once - is carried across unchanged rather than being
    " reduced to a single value the way FILTER_VALUE does.
    "
    " Both date properties are Edm.String holding YYYYMMDD (see the model
    " class), which moves into a DATS field character for character.
    DATA lv_prop TYPE string.

    FIELD-SYMBOLS <ls_filter> TYPE /iwbep/s_mgw_select_option.

    LOOP AT it_filter ASSIGNING <ls_filter>.
      lv_prop = <ls_filter>-property.
      TRANSLATE lv_prop TO UPPER CASE.
      CHECK lv_prop = to_upper( iv_property ).

      LOOP AT <ls_filter>-select_options ASSIGNING FIELD-SYMBOL(<ls_opt>).
        APPEND VALUE #( sign   = <ls_opt>-sign
                        option = <ls_opt>-option
                        low    = <ls_opt>-low
                        high   = <ls_opt>-high ) TO rt_range.
      ENDLOOP.

      RETURN.
    ENDLOOP.

  ENDMETHOD.


  METHOD apply_paging.

    " $skip then $top, applied after the caller has already recorded the
    " unpaged total for $inlinecount. TOP = 0 means the request carried no
    " $top at all - Gateway cannot distinguish that from "$top=0" here, so
    " the app asks for $top=1 when it only wants the count.
    IF is_paging-skip > 0.
      IF lines( ct_data ) <= is_paging-skip.
        CLEAR ct_data.
        RETURN.
      ENDIF.
      DELETE ct_data FROM 1 TO is_paging-skip.
    ENDIF.

    IF is_paging-top > 0 AND lines( ct_data ) > is_paging-top.
      DELETE ct_data FROM is_paging-top + 1.
    ENDIF.

  ENDMETHOD.


  METHOD /iwbep/if_mgw_appl_srv_runtime~get_entityset.

    DATA: lt_pend     TYPE zcl_zsol_scan_read_mpc=>tt_pick_pend,
          lt_plst     TYPE zcl_zsol_scan_read_mpc=>tt_plist,
          lt_hdr      TYPE zcl_zsol_scan_read_mpc=>tt_inv_hdr,
          lt_itm      TYPE zcl_zsol_scan_read_mpc=>tt_inv_itm,
          lt_resv     TYPE zcl_zsol_scan_read_mpc=>tt_resv,
          lt_chk      TYPE zcl_zsol_scan_read_mpc=>tt_so_check,
          lt_sob      TYPE zcl_zsol_scan_read_mpc=>tt_so_batch,
          lt_int      TYPE tt_pend_int,
          lr_deliv    TYPE tt_date_range,
          lr_creat    TYPE tt_date_range,
          lr_bukrs    TYPE tt_bukrs_range,
          lr_werks    TYPE zcl_zsol_app_auth=>ty_r_werks,
          ls_session  TYPE zcl_zsol_app_auth=>ty_session,
          lv_set      TYPE string,
          lv_key      TYPE string,
          lv_vbeln    TYPE vbeln_va,
          lv_huinv    TYPE huinv_nr,
          lv_doc_wrks TYPE werks_d,
          lv_open     TYPE resb-bdmng.

    lv_set = io_tech_request_context->get_entity_set_name( ).

    " One check, before any data is read, on every set. GET_REQUEST_HEADERS
    " carries the X-Scan-Token the app sends on every request. The return
    " value is what tells us which company codes and plants this operator
    " may see.
    ls_session = zcl_zsol_app_auth=>check_request(
      it_header = io_tech_request_context->get_request_headers( ) ).

    CASE lv_set.

      WHEN 'ZSOL_SO_PICK_PEND'.

        " Optional date windows. An empty range restricts nothing, so a
        " call without $filter behaves as it always has.
        "
        " CREATED_ON is the useful one. Open items carry requested
        " delivery dates going back to 2017, so filtering on DELIV_DATE
        " returns two rows for a recent month and everything otherwise;
        " order creation date is what somebody means by recent orders.
        lr_deliv = filter_date_range( it_filter   = it_filter_select_options
                                      iv_property = 'deliv_date' ).
        lr_creat = filter_date_range( it_filter   = it_filter_select_options
                                      iv_property = 'created_on' ).

        " The company codes this operator holds, as a SQL range. Left
        " empty for a service user - CHECK_REQUEST returns no grants for
        " SOLSYNCH's scanner - and an empty range restricts nothing, so
        " that app keeps seeing what it always did.
        "
        " A grant row with BUKRS = '*' means the whole estate, which is
        " not a company code the database can match. It has to empty the
        " range rather than join it, or the read returns nothing at all.
        LOOP AT ls_session-orgs INTO DATA(ls_grant).
          IF ls_grant-bukrs = zcl_zsol_app_auth=>gc_org_any.
            CLEAR lr_bukrs.
            EXIT.
          ENDIF.
          READ TABLE lr_bukrs TRANSPORTING NO FIELDS WITH KEY low = ls_grant-bukrs.
          IF sy-subrc <> 0.
            APPEND VALUE #( sign = 'I' option = 'EQ' low = ls_grant-bukrs ) TO lr_bukrs.
          ENDIF.
        ENDLOOP.

        " The dates are exposed as 8-character strings rather than dates
        " (see the model class). The casts are explicit because strict
        " ABAP SQL will not move a DATS into a CHAR(8) target on its own.
        "
        " Newest order first (05.09.2026). Sorting on the creation date
        " alone put every order raised on the same day in ascending
        " document-number order, so on a busy day the handheld's dropdown
        " opened on the morning's first order and the one just raised was
        " at the bottom. VBELN descending inside the date keeps the day's
        " newest at the top, and the $top the app sends cuts the oldest
        " rows, not the newest.
        SELECT ship_point, vbeln, posnr, shipto, shiptoparty, soldto, soldtoparty,
               CAST( deliv_date AS CHAR( 8 ) ) AS deliv_date,
               CAST( created_on AS CHAR( 8 ) ) AS created_on,
               bukrs, werks
          FROM zsol_so_pick_pend
          WHERE deliv_date IN @lr_deliv
            AND created_on IN @lr_creat
            AND bukrs      IN @lr_bukrs
          ORDER BY created_on DESCENDING, vbeln DESCENDING, posnr
          INTO CORRESPONDING FIELDS OF TABLE @lt_int.

        " The range above narrowed to the caller's company codes where it
        " could, which is the cheap half and the part the database can do.
        " The pair has still to be matched properly - somebody granted
        " 2000|2002 must not be let through by holding 8000|8001 - and a
        " row whose company code did not resolve matches no grant and is
        " not shown. Failing closed is the right way round here.
        IF ls_session-orgs IS INITIAL.
          lt_pend = CORRESPONDING #( lt_int ).
        ELSE.
          LOOP AT lt_int INTO DATA(ls_int).
            IF zcl_zsol_app_auth=>org_allowed( it_orgs  = ls_session-orgs
                                               iv_bukrs = ls_int-bukrs
                                               iv_werks = ls_int-werks ) = abap_true.
              APPEND CORRESPONDING #( ls_int ) TO lt_pend.
            ENDIF.
          ENDLOOP.
        ENDIF.

        es_response_context-inlinecount = lines( lt_pend ).
        apply_paging( EXPORTING is_paging = is_paging CHANGING ct_data = lt_pend ).

        copy_data_to_ref( EXPORTING is_data = lt_pend
                          CHANGING  cr_data = er_entityset ).

      WHEN 'ZSOL_PLIST'.

        " The packing list is read one sales order at a time. Refusing an
        " unfiltered call keeps this from becoming a dump of every packed
        " box in the plant.
        lv_key = filter_value( it_filter   = it_filter_select_options
                               iv_property = 'vbeln' ).
        IF lv_key IS INITIAL.
          fail( 'Select a sales order first' ).
        ENDIF.

        " Requiring an order is not the same as being allowed that order.
        " ZSOL_PLIST carries no plant of its own, so the check goes
        " through the order to its company code and item plants.
        "
        " The converted value is used for BOTH the check and the read.
        " Checking the padded form and then querying the raw one would
        " authorise one key and fetch another - harmless here because it
        " fails closed, but not something to leave in an access path.
        lv_vbeln = |{ lv_key ALPHA = IN }|.

        zcl_zsol_app_auth=>require_sales_order( it_orgs  = ls_session-orgs
                                                iv_vbeln = lv_vbeln ).

        SELECT boxno, vbeln, posnr, pklst, matnr, ptype, grade, HUCHK
          FROM zsol_plist
          WHERE vbeln = @lv_vbeln
          ORDER BY boxno
          INTO CORRESPONDING FIELDS OF TABLE @lt_plst.

        es_response_context-inlinecount = lines( lt_plst ).
        apply_paging( EXPORTING is_paging = is_paging CHANGING ct_data = lt_plst ).

        copy_data_to_ref( EXPORTING is_data = lt_plst
                          CHANGING  cr_data = er_entityset ).

      WHEN 'ZSOL_HUINV_HDR_PUSH'.

        " Open count documents only - the view already excludes closed
        " ones. Small list, and restricted to the caller's plants.
        " An empty range restricts nothing, which is what a session
        " carrying no grants is supposed to get.
        lr_werks = zcl_zsol_app_auth=>allowed_plants( ls_session-orgs ).

        SELECT huinv_nr, werks, crea_user
          FROM zsol_huinv_hdr_push
          WHERE werks IN @lr_werks
          ORDER BY huinv_nr
          INTO CORRESPONDING FIELDS OF TABLE @lt_hdr.

        es_response_context-inlinecount = lines( lt_hdr ).
        apply_paging( EXPORTING is_paging = is_paging CHANGING ct_data = lt_hdr ).

        copy_data_to_ref( EXPORTING is_data = lt_hdr
                          CHANGING  cr_data = er_entityset ).

      WHEN 'ZSOL_HUINV_ITM_PUSH'.

        " Always scoped to one count document, for the same reason as the
        " packing list above.
        lv_key = filter_value( it_filter   = it_filter_select_options
                               iv_property = 'huinv_nr' ).
        IF lv_key IS INITIAL.
          fail( 'Select an inventory document first' ).
        ENDIF.

        lv_huinv = lv_key.

        " The plant lives on the count document's header, not on the
        " items, so it has to be read before the items are. ZHUINV_HDR
        " rather than the ZSOL_HUINV_HDR_PUSH view on purpose: the view
        " shows only open documents, and refusing to display the items of
        " a document that has since been closed would be a new bug.
        SELECT SINGLE werks FROM zhuinv_hdr
          WHERE huinv_nr = @lv_huinv
          INTO @lv_doc_wrks.

        IF sy-subrc <> 0.
          fail( |Inventory document { lv_key } not found| ).
        ENDIF.

        zcl_zsol_app_auth=>require_plant( it_orgs  = ls_session-orgs
                                          iv_werks = lv_doc_wrks ).

        SELECT huinv_nr, exidv, matnr, charg, lgort, vhilm, inv_by
          FROM zsol_huinv_itm_push
          WHERE huinv_nr = @lv_huinv
          ORDER BY exidv
          INTO CORRESPONDING FIELDS OF TABLE @lt_itm.

        es_response_context-inlinecount = lines( lt_itm ).
        apply_paging( EXPORTING is_paging = is_paging CHANGING ct_data = lt_itm ).

        copy_data_to_ref( EXPORTING is_data = lt_itm
                          CHANGING  cr_data = er_entityset ).

      WHEN 'ZSOL_RESERVATION'.

        " Open manual reservation items for the HU Movement screen: record
        " type MR (a reservation somebody created, not an order's
        " component list), not deleted, not finally issued, quantity still
        " open, goods movement allowed. Scoped to the caller's plants on
        " EITHER side of the transfer, so a reservation that brings stock
        " into a granted plant is offered as well as one that takes it
        " out. An empty range restricts nothing, as everywhere here.
        "
        " Newest first and capped: production carries years of
        " half-withdrawn reservations, and the handheld shows a dropdown.
        lr_werks = zcl_zsol_app_auth=>allowed_plants( ls_session-orgs ).

        SELECT r~rsnum, r~rspos, r~bwart, r~matnr, r~werks, r~lgort,
               r~umwrk, r~umlgo, r~bdmng, r~enmng, r~meins, r~bdter, r~sgtxt,
               k~rsdat, k~wempf
          FROM resb AS r
          INNER JOIN rkpf AS k ON k~rsnum = r~rsnum
          WHERE r~bdart = 'MR'
            AND r~xloek = @space
            AND r~kzear = @space
            AND r~xwaok = 'X'
            AND r~bdmng > r~enmng
            AND ( r~werks IN @lr_werks OR r~umwrk IN @lr_werks )
          ORDER BY k~rsdat DESCENDING, r~rsnum DESCENDING, r~rspos
          INTO TABLE @DATA(lt_rs)
          UP TO 300 ROWS.

        IF lt_rs IS NOT INITIAL.
          SELECT matnr, maktx FROM makt
            FOR ALL ENTRIES IN @lt_rs
            WHERE matnr = @lt_rs-matnr
              AND spras = @sy-langu
            INTO TABLE @DATA(lt_makt).
          SORT lt_makt BY matnr.
        ENDIF.

        LOOP AT lt_rs INTO DATA(ls_rs).
          APPEND INITIAL LINE TO lt_resv ASSIGNING FIELD-SYMBOL(<ls_rv>).
          <ls_rv>-rsnum = ls_rs-rsnum.
          <ls_rv>-rspos = ls_rs-rspos.
          <ls_rv>-bwart = ls_rs-bwart.
          <ls_rv>-matnr = ls_rs-matnr.
          <ls_rv>-werks = ls_rs-werks.
          <ls_rv>-lgort = ls_rs-lgort.
          <ls_rv>-umwrk = ls_rs-umwrk.
          <ls_rv>-umlgo = ls_rs-umlgo.
          lv_open = ls_rs-bdmng - ls_rs-enmng.
          <ls_rv>-open_qty = |{ lv_open NUMBER = RAW }|.
          <ls_rv>-meins = ls_rs-meins.
          <ls_rv>-rsdat = ls_rs-rsdat.
          <ls_rv>-bdter = ls_rs-bdter.
          <ls_rv>-wempf = ls_rs-wempf.
          <ls_rv>-sgtxt = ls_rs-sgtxt.
          READ TABLE lt_makt INTO DATA(ls_makt) WITH KEY matnr = ls_rs-matnr BINARY SEARCH.
          IF sy-subrc = 0.
            <ls_rv>-maktx = ls_makt-maktx.
          ENDIF.
        ENDLOOP.

        es_response_context-inlinecount = lines( lt_resv ).
        apply_paging( EXPORTING is_paging = is_paging CHANGING ct_data = lt_resv ).

        copy_data_to_ref( EXPORTING is_data = lt_resv
                          CHANGING  cr_data = er_entityset ).

      WHEN 'ZSOL_SO_BOXCHECK'.

        " Why the Packing List offers no boxes for this order: one row per
        " item with the verdict of every rule ZRPT_SALES_SCAN applies. Read
        " for one order at a time, and only an order the caller may see.
        lv_key = filter_value( it_filter   = it_filter_select_options
                               iv_property = 'vbeln' ).
        IF lv_key IS INITIAL.
          fail( 'Select a sales order first' ).
        ENDIF.
        lv_vbeln = |{ lv_key ALPHA = IN }|.

        zcl_zsol_app_auth=>require_sales_order( it_orgs  = ls_session-orgs
                                                iv_vbeln = lv_vbeln ).

        lt_chk = check_to_rows( zcl_zsol_so_boxcheck=>check_order( lv_vbeln ) ).

        es_response_context-inlinecount = lines( lt_chk ).
        apply_paging( EXPORTING is_paging = is_paging CHANGING ct_data = lt_chk ).

        copy_data_to_ref( EXPORTING is_data = lt_chk
                          CHANGING  cr_data = er_entityset ).

      WHEN 'ZSOL_SO_BATCH'.

        " The batches named on the order's items (ZVBAP_BATCH), read for
        " one order the caller may see.
        lv_key = filter_value( it_filter   = it_filter_select_options
                               iv_property = 'vbeln' ).
        IF lv_key IS INITIAL.
          fail( 'Select a sales order first' ).
        ENDIF.
        lv_vbeln = |{ lv_key ALPHA = IN }|.

        zcl_zsol_app_auth=>require_sales_order( it_orgs  = ls_session-orgs
                                                iv_vbeln = lv_vbeln ).

        LOOP AT zcl_zsol_so_boxcheck=>get_batches( lv_vbeln ) INTO DATA(ls_sb).
          APPEND VALUE #( vbeln = ls_sb-vbeln posnr = ls_sb-posnr charg = ls_sb-charg ) TO lt_sob.
        ENDLOOP.

        es_response_context-inlinecount = lines( lt_sob ).
        apply_paging( EXPORTING is_paging = is_paging CHANGING ct_data = lt_sob ).

        copy_data_to_ref( EXPORTING is_data = lt_sob
                          CHANGING  cr_data = er_entityset ).

      WHEN OTHERS.

        super->/iwbep/if_mgw_appl_srv_runtime~get_entityset(
          EXPORTING
            iv_entity_name           = iv_entity_name
            iv_entity_set_name       = iv_entity_set_name
            iv_source_name           = iv_source_name
            it_filter_select_options = it_filter_select_options
            it_order                 = it_order
            is_paging                = is_paging
            it_navigation_path       = it_navigation_path
            it_key_tab               = it_key_tab
            iv_filter_string         = iv_filter_string
            iv_search_string         = iv_search_string
            io_tech_request_context  = io_tech_request_context
          IMPORTING
            er_entityset             = er_entityset ).

    ENDCASE.

  ENDMETHOD.

  METHOD check_to_rows.

    LOOP AT it_items INTO DATA(ls_i).
      APPEND INITIAL LINE TO rt_rows ASSIGNING FIELD-SYMBOL(<ls_r>).
      <ls_r>-vbeln       = ls_i-vbeln.
      <ls_r>-posnr       = ls_i-posnr.
      <ls_r>-matnr       = ls_i-matnr.
      <ls_r>-arktx       = ls_i-arktx.
      <ls_r>-werks       = ls_i-werks.
      <ls_r>-lgort       = ls_i-lgort.
      <ls_r>-charg       = ls_i-charg.
      <ls_r>-kwmeng      = |{ ls_i-kwmeng NUMBER = RAW }|.
      <ls_r>-vrkme       = ls_i-vrkme.
      <ls_r>-dis_qty     = |{ ls_i-dis_qty NUMBER = RAW }|.
      <ls_r>-open_qty    = |{ ls_i-open_qty NUMBER = RAW }|.
      <ls_r>-abgru       = ls_i-abgru.
      <ls_r>-zzsize      = ls_i-zzsize.
      <ls_r>-zzsiz1      = ls_i-zzsiz1.
      <ls_r>-zzsiz2      = ls_i-zzsiz2.
      <ls_r>-zzgrade     = ls_i-zzgrade.
      <ls_r>-zzgrad1     = ls_i-zzgrad1.
      <ls_r>-zzgrad2     = ls_i-zzgrad2.
      <ls_r>-so_batches  = ls_i-so_batches.
      <ls_r>-batch_src   = ls_i-batch_src.
      <ls_r>-cand_cnt    = ls_i-cand_cnt.
      <ls_r>-match_cnt   = ls_i-match_cnt.
      <ls_r>-match_wt    = |{ ls_i-match_wt NUMBER = RAW }|.
      <ls_r>-need_batch  = ls_i-need_batch.
      <ls_r>-other_lgort = ls_i-other_lgort.
      <ls_r>-other_size  = ls_i-other_size.
      <ls_r>-other_grade = ls_i-other_grade.
      <ls_r>-other_so    = ls_i-other_so.
      <ls_r>-on_deliv    = ls_i-on_deliv.
      <ls_r>-not_posted  = ls_i-not_posted.
      <ls_r>-hint        = ls_i-hint.
    ENDLOOP.

  ENDMETHOD.


  METHOD key_value.

    LOOP AT it_key_tab INTO DATA(ls_key).
      IF to_upper( ls_key-name ) = to_upper( iv_name ).
        rv_value = ls_key-value.
        RETURN.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.


  METHOD /iwbep/if_mgw_appl_srv_runtime~create_entity.

    " POST ZSOL_SO_BATCH: name a batch on a sales order item. The one write
    " in this service. Needs a signed-in user holding the SOCHG screen, and
    " the order has to be one that user may see.
    DATA: ls_in    TYPE zcl_zsol_scan_read_mpc=>ts_so_batch,
          ls_out   TYPE zcl_zsol_scan_read_mpc=>ts_so_batch,
          lv_vbeln TYPE vbeln_va,
          lv_posnr TYPE posnr_va,
          lv_charg TYPE charg_d,
          lv_error TYPE string.

    IF io_tech_request_context->get_entity_set_name( ) <> 'ZSOL_SO_BATCH'.
      fail( 'This set cannot be created' ).
    ENDIF.

    DATA(ls_session) = zcl_zsol_app_auth=>check_request(
      it_header  = io_tech_request_context->get_request_headers( )
      iv_feature = 'SOCHG' ).

    " CHECK_REQUEST lets a service user (SOLSYNCH's scanner) past the
    " feature check. Nothing but a signed-in person may change an order.
    IF ls_session-orgs IS INITIAL.
      fail( 'Sign in to the Scan Suite to change a sales order' ).
    ENDIF.

    IF io_data_provider IS NOT BOUND.
      fail( 'No data supplied' ).
    ENDIF.
    io_data_provider->read_entry_data( IMPORTING es_data = ls_in ).

    lv_vbeln = |{ ls_in-vbeln ALPHA = IN }|.
    lv_posnr = |{ ls_in-posnr ALPHA = IN }|.
    lv_charg = to_upper( condense( ls_in-charg ) ).

    IF lv_vbeln IS INITIAL OR lv_posnr IS INITIAL.
      fail( 'Sales order and item are required' ).
    ENDIF.

    zcl_zsol_app_auth=>require_sales_order( it_orgs  = ls_session-orgs
                                            iv_vbeln = lv_vbeln ).

    zcl_zsol_so_boxcheck=>assign_batch( EXPORTING iv_vbeln = lv_vbeln
                                                  iv_posnr = lv_posnr
                                                  iv_charg = lv_charg
                                                  iv_user  = ls_session-username
                                        IMPORTING ev_error = lv_error ).
    IF lv_error IS NOT INITIAL.
      fail( lv_error ).
    ENDIF.

    ls_out-vbeln   = lv_vbeln.
    ls_out-posnr   = lv_posnr.
    ls_out-charg   = lv_charg.
    ls_out-message = |Batch { lv_charg } assigned to item { lv_posnr ALPHA = OUT } of order { lv_vbeln ALPHA = OUT } by { ls_session-username }|.

    copy_data_to_ref( EXPORTING is_data = ls_out
                      CHANGING  cr_data = er_entity ).

  ENDMETHOD.


  METHOD /iwbep/if_mgw_appl_srv_runtime~delete_entity.

    " DELETE ZSOL_SO_BATCH(vbeln='..',posnr='..',charg='..'): take a batch
    " off an item. Same guard as the POST.
    DATA: lv_vbeln TYPE vbeln_va,
          lv_posnr TYPE posnr_va,
          lv_charg TYPE charg_d,
          lv_error TYPE string.

    IF io_tech_request_context->get_entity_set_name( ) <> 'ZSOL_SO_BATCH'.
      fail( 'This set cannot be deleted' ).
    ENDIF.

    DATA(ls_session) = zcl_zsol_app_auth=>check_request(
      it_header  = io_tech_request_context->get_request_headers( )
      iv_feature = 'SOCHG' ).

    IF ls_session-orgs IS INITIAL.
      fail( 'Sign in to the Scan Suite to change a sales order' ).
    ENDIF.

    lv_vbeln = |{ key_value( it_key_tab = it_key_tab iv_name = 'vbeln' ) ALPHA = IN }|.
    lv_posnr = |{ key_value( it_key_tab = it_key_tab iv_name = 'posnr' ) ALPHA = IN }|.
    lv_charg = to_upper( key_value( it_key_tab = it_key_tab iv_name = 'charg' ) ).

    IF lv_vbeln IS INITIAL OR lv_posnr IS INITIAL OR lv_charg IS INITIAL.
      fail( 'Sales order, item and batch are required' ).
    ENDIF.

    zcl_zsol_app_auth=>require_sales_order( it_orgs  = ls_session-orgs
                                            iv_vbeln = lv_vbeln ).

    zcl_zsol_so_boxcheck=>remove_batch( EXPORTING iv_vbeln = lv_vbeln
                                                  iv_posnr = lv_posnr
                                                  iv_charg = lv_charg
                                                  iv_user  = ls_session-username
                                        IMPORTING ev_error = lv_error ).
    IF lv_error IS NOT INITIAL.
      fail( lv_error ).
    ENDIF.

  ENDMETHOD.

ENDCLASS.
