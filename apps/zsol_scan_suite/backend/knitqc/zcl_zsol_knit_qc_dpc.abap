class ZCL_ZSOL_KNIT_QC_DPC definition
  public
  inheriting from /IWBEP/CL_MGW_PUSH_ABS_DATA
  create public .

public section.

* ----------------------------------------------------------------------
* Scan Suite - Knitting Roll QC data provider. See ZCL_ZSOL_KNIT_QC_MPC
* for the model and ZCL_ZKNIT_ROLL_QC for the rules; this class only
* checks the caller and translates between the two.
*
* Every call needs a valid app session (X-Scan-Token). Reads are scoped
* to the caller's plants through ZCL_ZSOL_APP_AUTH=>ALLOWED_PLANTS; the
* write (POST RollSet) needs the KNITQC screen and the plant the roll
* belongs to. The plant is taken from the roll itself - the label's print
* record - never from the payload, so an operator cannot record QC for a
* plant they do not hold by naming a different one.
*
* RollSet GET:  $filter=Zmrno eq 'MK0013/5443' [and Werks eq '8001']
*               -> the roll, resolved, whether or not QC has seen it.
* RollSet POST: Action = PQC   PqcGrade, PqcDefects, PqcRemark, DyeSample
*               Action = DRECV (sample arrived at the lab)
*               Action = DRES  DqcStatus C or F, DqcRemark
* HoldSet / PendingDyeSet: no filter needed.
* ProductionSet: $filter=PqcDate ge '20260901' and PqcDate le '20260906'
*               [and Aufnr eq '...'] [and Arbpl eq '...']; today when absent.
* ----------------------------------------------------------------------

  methods /IWBEP/IF_MGW_APPL_SRV_RUNTIME~GET_ENTITYSET
    redefinition .
  methods /IWBEP/IF_MGW_APPL_SRV_RUNTIME~CREATE_ENTITY
    redefinition .

protected section.

  methods CHECK_SUBSCRIPTION_AUTHORITY
    redefinition .

private section.

  types:
    begin of TS_DATE_RANGE,
      sign   type c length 1,
      option type c length 2,
      low    type d,
      high   type d,
    end of TS_DATE_RANGE .
  types:
    TT_DATE_RANGE type standard table of TS_DATE_RANGE with empty key .

  methods FILTER_VALUE
    importing
      !IT_FILTER type /IWBEP/T_MGW_SELECT_OPTION
      !IV_PROPERTY type STRING
    returning
      value(RV_VALUE) type STRING .

  methods FILTER_DATE_RANGE
    importing
      !IT_FILTER type /IWBEP/T_MGW_SELECT_OPTION
      !IV_PROPERTY type STRING
    returning
      value(RT_RANGE) type TT_DATE_RANGE .

  methods FAIL
    importing
      !IV_MESSAGE type STRING
    raising
      /IWBEP/CX_MGW_BUSI_EXCEPTION .

  methods TO_ROWS
    importing
      !IT_ROLLS type ZCL_ZKNIT_ROLL_QC=>TT_ROLL
    returning
      value(RT_ROWS) type ZCL_ZSOL_KNIT_QC_MPC=>TT_ROLL .

  methods TO_ROW
    importing
      !IS_ROLL type ZCL_ZKNIT_ROLL_QC=>TY_ROLL
    returning
      value(RS_ROW) type ZCL_ZSOL_KNIT_QC_MPC=>TS_ROLL .

  methods APPLY_PAGING
    importing
      !IS_PAGING type /IWBEP/S_MGW_PAGING
    changing
      !CT_DATA type STANDARD TABLE .

ENDCLASS.



CLASS ZCL_ZSOL_KNIT_QC_DPC IMPLEMENTATION.


  METHOD check_subscription_authority.
    RETURN.
  ENDMETHOD.


  METHOD fail.
    DATA lv_msg TYPE c LENGTH 220.
    lv_msg = iv_message.
    RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
      EXPORTING
        textid  = /iwbep/cx_mgw_busi_exception=>business_error
        message = lv_msg.
  ENDMETHOD.


  METHOD filter_value.
    LOOP AT it_filter ASSIGNING FIELD-SYMBOL(<ls_filter>).
      IF to_upper( <ls_filter>-property ) = to_upper( iv_property ).
        READ TABLE <ls_filter>-select_options ASSIGNING FIELD-SYMBOL(<ls_opt>) INDEX 1.
        IF sy-subrc = 0.
          rv_value = <ls_opt>-low.
        ENDIF.
        RETURN.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.


  METHOD filter_date_range.
    LOOP AT it_filter ASSIGNING FIELD-SYMBOL(<ls_filter>).
      CHECK to_upper( <ls_filter>-property ) = to_upper( iv_property ).
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


  METHOD to_row.
    rs_row-werks         = is_roll-werks.
    rs_row-arbpl         = is_roll-arbpl.
    rs_row-mrno          = is_roll-mrno.
    rs_row-zmrno         = is_roll-zmrno.
    rs_row-aufnr         = is_roll-aufnr.
    rs_row-matnr         = is_roll-matnr.
    rs_row-maktx         = is_roll-maktx.
    rs_row-print_date    = is_roll-print_date.
    rs_row-pqc_date      = is_roll-pqc_date.
    rs_row-pqc_time      = is_roll-pqc_time.
    rs_row-pqc_user      = is_roll-pqc_user.
    rs_row-pqc_grade     = is_roll-pqc_grade.
    rs_row-pqc_grade_txt = is_roll-pqc_grade_txt.
    rs_row-pqc_defects   = is_roll-pqc_defects.
    rs_row-pqc_remark    = is_roll-pqc_remark.
    rs_row-dqc_status    = is_roll-dqc_status.
    rs_row-dqc_sent_date = is_roll-dqc_sent_date.
    rs_row-dqc_recv_date = is_roll-dqc_recv_date.
    rs_row-dqc_res_date  = is_roll-dqc_res_date.
    rs_row-dqc_res_user  = is_roll-dqc_res_user.
    rs_row-dqc_remark    = is_roll-dqc_remark.
    rs_row-days_pending  = is_roll-days_pending.
    rs_row-hold          = COND #( WHEN is_roll-hold = abap_true THEN 'X' ELSE '' ).
    rs_row-pack_boxno    = is_roll-pack_boxno.
    rs_row-pack_grade    = is_roll-pack_grade.
    rs_row-pack_date     = is_roll-pack_date.
    IF is_roll-pack_netwt IS NOT INITIAL.
      rs_row-pack_netwt  = |{ is_roll-pack_netwt NUMBER = RAW }|.
    ENDIF.
    rs_row-exists        = COND #( WHEN is_roll-exists = abap_true THEN 'X' ELSE '' ).
    " Blank dates travel as '' rather than '00000000'.
    IF is_roll-print_date IS INITIAL.    CLEAR rs_row-print_date.    ENDIF.
    IF is_roll-pqc_date IS INITIAL.      CLEAR rs_row-pqc_date.      ENDIF.
    IF is_roll-pqc_time IS INITIAL AND is_roll-pqc_date IS INITIAL. CLEAR rs_row-pqc_time. ENDIF.
    IF is_roll-dqc_sent_date IS INITIAL. CLEAR rs_row-dqc_sent_date. ENDIF.
    IF is_roll-dqc_recv_date IS INITIAL. CLEAR rs_row-dqc_recv_date. ENDIF.
    IF is_roll-dqc_res_date IS INITIAL.  CLEAR rs_row-dqc_res_date.  ENDIF.
    IF is_roll-pack_date IS INITIAL.     CLEAR rs_row-pack_date.     ENDIF.
  ENDMETHOD.


  METHOD to_rows.
    LOOP AT it_rolls ASSIGNING FIELD-SYMBOL(<ls_roll>).
      APPEND to_row( <ls_roll> ) TO rt_rows.
    ENDLOOP.
  ENDMETHOD.


  METHOD /iwbep/if_mgw_appl_srv_runtime~get_entityset.

    DATA: lt_rows    TYPE zcl_zsol_knit_qc_mpc=>tt_roll,
          lt_defects TYPE zcl_zsol_knit_qc_mpc=>tt_defect,
          lt_grades  TYPE zcl_zsol_knit_qc_mpc=>tt_grade,
          lr_werks   TYPE zcl_zsol_app_auth=>ty_r_werks,
          lr_date    TYPE tt_date_range,
          ls_roll    TYPE zcl_zknit_roll_qc=>ty_roll,
          lv_set     TYPE string,
          lv_scan    TYPE string,
          lv_werks   TYPE werks_d,
          lv_from    TYPE d,
          lv_to      TYPE d,
          lv_aufnr   TYPE aufnr,
          lv_arbpl   TYPE arbpl,
          lv_error   TYPE string.

    lv_set = io_tech_request_context->get_entity_set_name( ).

    DATA(ls_session) = zcl_zsol_app_auth=>check_request(
      it_header = io_tech_request_context->get_request_headers( ) ).

    lr_werks = zcl_zsol_app_auth=>allowed_plants( ls_session-orgs ).

    CASE lv_set.

      WHEN zcl_zsol_knit_qc_mpc=>gc_set_roll.

        lv_scan  = filter_value( it_filter = it_filter_select_options iv_property = 'Zmrno' ).
        lv_werks = filter_value( it_filter = it_filter_select_options iv_property = 'Werks' ).
        IF lv_scan IS INITIAL.
          fail( 'Scan a roll label first' ).
        ENDIF.

        zcl_zknit_roll_qc=>resolve_roll( EXPORTING iv_scan  = lv_scan
                                                   iv_werks = lv_werks
                                         IMPORTING es_roll  = ls_roll
                                                   ev_error = lv_error ).
        IF lv_error IS NOT INITIAL.
          fail( lv_error ).
        ENDIF.

        " The plant is the roll's, and it has to be one the caller holds.
        zcl_zsol_app_auth=>require_plant( it_orgs  = ls_session-orgs
                                          iv_werks = ls_roll-werks ).

        APPEND to_row( ls_roll ) TO lt_rows.

      WHEN zcl_zsol_knit_qc_mpc=>gc_set_hold.
        lt_rows = to_rows( zcl_zknit_roll_qc=>get_hold_list( lr_werks ) ).

      WHEN zcl_zsol_knit_qc_mpc=>gc_set_pending.
        lt_rows = to_rows( zcl_zknit_roll_qc=>get_pending_dye( lr_werks ) ).

      WHEN zcl_zsol_knit_qc_mpc=>gc_set_prod.
        " Date window from PqcDate ge/le/BT; today when none is sent.
        lr_date = filter_date_range( it_filter = it_filter_select_options iv_property = 'PqcDate' ).
        lv_from = sy-datum.
        lv_to   = sy-datum.
        LOOP AT lr_date INTO DATA(ls_d).
          CASE ls_d-option.
            WHEN 'BT'. lv_from = ls_d-low. lv_to = ls_d-high.
            WHEN 'GE' OR 'GT'. lv_from = ls_d-low.
            WHEN 'LE' OR 'LT'. lv_to = ls_d-low.
            WHEN 'EQ'. lv_from = ls_d-low. lv_to = ls_d-low.
          ENDCASE.
        ENDLOOP.
        lv_aufnr = filter_value( it_filter = it_filter_select_options iv_property = 'Aufnr' ).
        IF lv_aufnr IS NOT INITIAL.
          lv_aufnr = |{ lv_aufnr ALPHA = IN }|.
        ENDIF.
        lv_arbpl = to_upper( filter_value( it_filter = it_filter_select_options iv_property = 'Arbpl' ) ).
        lt_rows = to_rows( zcl_zknit_roll_qc=>get_production( it_werks     = lr_werks
                                                              iv_date_from = lv_from
                                                              iv_date_to   = lv_to
                                                              iv_aufnr     = lv_aufnr
                                                              iv_arbpl     = lv_arbpl ) ).

      WHEN zcl_zsol_knit_qc_mpc=>gc_set_defect.
        lv_werks = filter_value( it_filter = it_filter_select_options iv_property = 'Werks' ).
        LOOP AT zcl_zknit_roll_qc=>get_defect_codes( lv_werks ) INTO DATA(ls_def).
          APPEND VALUE #( werks = ls_def-werks dcode = ls_def-dcode
                          descr = ls_def-descr sortno = ls_def-sortno ) TO lt_defects.
        ENDLOOP.
        es_response_context-inlinecount = lines( lt_defects ).
        copy_data_to_ref( EXPORTING is_data = lt_defects CHANGING cr_data = er_entityset ).
        RETURN.

      WHEN zcl_zsol_knit_qc_mpc=>gc_set_grade.
        LOOP AT zcl_zknit_roll_qc=>get_grades( ) INTO DATA(ls_g).
          APPEND VALUE #( gcode = ls_g-gcode gdesc = ls_g-gdesc ) TO lt_grades.
        ENDLOOP.
        es_response_context-inlinecount = lines( lt_grades ).
        copy_data_to_ref( EXPORTING is_data = lt_grades CHANGING cr_data = er_entityset ).
        RETURN.

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
        RETURN.
    ENDCASE.

    es_response_context-inlinecount = lines( lt_rows ).
    apply_paging( EXPORTING is_paging = is_paging CHANGING ct_data = lt_rows ).
    copy_data_to_ref( EXPORTING is_data = lt_rows CHANGING cr_data = er_entityset ).

  ENDMETHOD.


  METHOD /iwbep/if_mgw_appl_srv_runtime~create_entity.

    DATA: ls_in    TYPE zcl_zsol_knit_qc_mpc=>ts_roll,
          ls_out   TYPE zcl_zsol_knit_qc_mpc=>ts_roll,
          ls_roll  TYPE zcl_zknit_roll_qc=>ty_roll,
          ls_key   TYPE zcl_zknit_roll_qc=>ty_key,
          lv_scan  TYPE string,
          lv_werks TYPE werks_d,
          lv_error TYPE string.

    IF io_tech_request_context->get_entity_set_name( ) <> zcl_zsol_knit_qc_mpc=>gc_set_roll.
      fail( 'Only RollSet accepts a POST' ).
    ENDIF.

    " A write: a signed-in user who holds the Knitting QC screen.
    DATA(ls_session) = zcl_zsol_app_auth=>check_request(
      it_header  = io_tech_request_context->get_request_headers( )
      iv_feature = 'KNITQC' ).

    IF io_data_provider IS NOT BOUND.
      fail( 'No data supplied' ).
    ENDIF.
    io_data_provider->read_entry_data( IMPORTING es_data = ls_in ).

    " The roll is named by its label (Zmrno) or by the three key parts.
    lv_scan = ls_in-zmrno.
    IF lv_scan IS INITIAL AND ls_in-arbpl IS NOT INITIAL.
      lv_scan = |{ ls_in-arbpl }/{ ls_in-mrno }|.
    ENDIF.
    lv_werks = ls_in-werks.

    " Resolve first, so the plant that is checked is the roll's own.
    zcl_zknit_roll_qc=>resolve_roll( EXPORTING iv_scan  = lv_scan
                                               iv_werks = lv_werks
                                     IMPORTING es_roll  = ls_roll
                                               ev_error = lv_error ).
    IF lv_error IS NOT INITIAL.
      fail( lv_error ).
    ENDIF.
    zcl_zsol_app_auth=>require_plant( it_orgs  = ls_session-orgs
                                      iv_werks = ls_roll-werks ).

    ls_key-werks = ls_roll-werks.
    ls_key-arbpl = ls_roll-arbpl.
    ls_key-mrno  = ls_roll-mrno.
    ls_key-zmrno = ls_roll-zmrno.

    CASE to_upper( ls_in-action ).

      WHEN 'PQC'.
        IF ls_roll-pack_boxno IS NOT INITIAL AND ls_roll-exists = abap_false.
          " Packed before QC ever saw it. Recording is still allowed - the
          " production list should be complete - but the operator is told.
          ls_out-message = |Note: roll { ls_roll-zmrno } was already packed as box { ls_roll-pack_boxno } on { ls_roll-pack_date DATE = USER }. |.
        ENDIF.
        zcl_zknit_roll_qc=>record_physical_qc(
          EXPORTING is_key        = ls_key
                    iv_user       = ls_session-username
                    iv_grade      = CONV #( to_upper( ls_in-pqc_grade ) )
                    iv_defects    = ls_in-pqc_defects
                    iv_remark     = ls_in-pqc_remark
                    iv_dye_sample = xsdbool( ls_in-dye_sample = 'X' )
          IMPORTING es_roll       = ls_roll
                    ev_error      = lv_error ).
        IF lv_error IS NOT INITIAL.
          fail( lv_error ).
        ENDIF.
        ls_out-message = ls_out-message &&
          COND #( WHEN ls_roll-dqc_status = zcl_zknit_roll_qc=>gc_dqc_sent
                  THEN |Physical QC saved - grade { ls_roll-pqc_grade }. Sample to Dyeing QC: roll is on HOLD until cleared.|
                  ELSE |Physical QC saved - grade { ls_roll-pqc_grade }.| ).

      WHEN 'DRECV'.
        zcl_zknit_roll_qc=>record_dye_received(
          EXPORTING is_key   = ls_key
                    iv_user  = ls_session-username
          IMPORTING es_roll  = ls_roll
                    ev_error = lv_error ).
        IF lv_error IS NOT INITIAL.
          fail( lv_error ).
        ENDIF.
        ls_out-message = |Sample received - roll { ls_roll-zmrno } stays on hold until the result is entered.|.

      WHEN 'DRES'.
        zcl_zknit_roll_qc=>record_dye_result(
          EXPORTING is_key    = ls_key
                    iv_user   = ls_session-username
                    iv_result = CONV char1( to_upper( ls_in-dqc_status ) )
                    iv_remark = ls_in-dqc_remark
          IMPORTING es_roll   = ls_roll
                    ev_error  = lv_error ).
        IF lv_error IS NOT INITIAL.
          fail( lv_error ).
        ENDIF.
        ls_out-message = COND #( WHEN ls_roll-dqc_status = zcl_zknit_roll_qc=>gc_dqc_cleared
                                 THEN |Dyeing QC CLEARED - roll { ls_roll-zmrno } may be packed.|
                                 ELSE |Dyeing QC FAILED - roll { ls_roll-zmrno } cannot be packed as 1ST quality.| ).

      WHEN OTHERS.
        fail( |Unknown action { ls_in-action } - use PQC, DRECV or DRES| ).
    ENDCASE.

    DATA(lv_msg) = ls_out-message.
    ls_out = to_row( ls_roll ).
    ls_out-action  = to_upper( ls_in-action ).
    ls_out-message = lv_msg.

    copy_data_to_ref( EXPORTING is_data = ls_out CHANGING cr_data = er_entity ).

  ENDMETHOD.

ENDCLASS.
