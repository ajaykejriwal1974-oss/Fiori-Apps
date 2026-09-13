*&---------------------------------------------------------------------*
*&  Include           MZ_PP_CO11NF01
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Form  VAL_REQ_VORNR
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM val_req_vornr .

  DATA: lt_dynpfields      TYPE STANDARD TABLE OF dynpread WITH HEADER LINE,
        lt_return_tab      TYPE STANDARD TABLE OF ddshretval,
        lt_dynpfld_mapping TYPE STANDARD TABLE OF dselc,
        lt_dialog_tab      TYPE STANDARD TABLE OF rclst,
        lt_dialog_tab_sop  TYPE STANDARD TABLE OF rclst,
        lt_dialog_tab_conf TYPE STANDARD TABLE OF rulst.

  DATA: BEGIN OF lt_values OCCURS 0,
          vornr   TYPE afvgd-vornr,
          aplfl   TYPE afvgd-aplfl,
          mgvrg   TYPE afvgd-mgvrg,
          meinh   TYPE afvgd-meinh,
          ltxa1   TYPE afvgd-ltxa1,
          lmnga   LIKE afvgd-lmnga,
          xmnga   TYPE afvgd-xmnga,
          rmnga   TYPE afvgd-rmnga,
          arbpl   TYPE afvgd-arbpl,
          werks   TYPE afvgd-werks,
          flg_mst TYPE afvgd-flg_mst,
        END   OF lt_values.

  DATA: BEGIN OF lt_values_pi OCCURS 0,
          vornr TYPE afvgd-vornr,
          aplfl TYPE afvgd-aplfl,
          mgvrg TYPE afvgd-mgvrg,
          meinh TYPE afvgd-meinh,
          ltxa1 TYPE afvgd-ltxa1,
          lmnga TYPE afvgd-lmnga,
          xmnga TYPE afvgd-xmnga,
          arbpl TYPE afvgd-arbpl,
          werks TYPE afvgd-werks,
          phflg TYPE afvgd-phflg,
        END   OF lt_values_pi.

  DATA: ls_coruf           TYPE coruf,
        ls_dialog_wa       TYPE rclst,
        ls_dynpfld_mapping TYPE dselc,
        ls_caufvd          TYPE caufvd,
        ls_tcoru           TYPE tcoru,
        ls_afvgd           TYPE afvgd,
        ls_afvgd_sav       TYPE afvgd.

  DATA: l_repid LIKE sy-repid,
        l_dynnr LIKE sy-dynnr,
        l_aufnr TYPE afrud-aufnr.


  l_repid = sy-repid.
  l_dynnr = sy-dynnr.

  lt_dynpfields-fieldname = 'WA_TAB-AUFNR'.
  APPEND lt_dynpfields.

  CALL FUNCTION 'DYNP_VALUES_READ'
    EXPORTING
      dyname     = l_repid
      dynumb     = l_dynnr
    TABLES
      dynpfields = lt_dynpfields
    EXCEPTIONS
      OTHERS     = 0.

  READ TABLE lt_dynpfields INDEX 1.
  IF NOT lt_dynpfields-fieldvalue IS INITIAL.
    CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
      EXPORTING
        input  = lt_dynpfields-fieldvalue
      IMPORTING
        output = l_aufnr
      EXCEPTIONS
        OTHERS = 0.
  ENDIF.

  IF l_aufnr IS INITIAL.
    MESSAGE i151(ru).
    EXIT.
  ENDIF.

  PERFORM get_afvgd_data IN PROGRAM saplcorf USING ls_afvgd_sav.

  CALL FUNCTION 'CO_BT_CAUFV_READ_WITH_KEY'
    EXPORTING
      aufnr_act  = l_aufnr
    IMPORTING
      caufvd_exp = ls_caufvd
    EXCEPTIONS
      not_found  = 1
      OTHERS     = 2.

  IF NOT sy-subrc IS INITIAL OR
     ls_caufvd-aufnr <> wa_tab-aufnr.

    ls_coruf-aufnr = l_aufnr.
    CALL FUNCTION 'CO_RU_GET_ORDER_HEADER'
      EXPORTING
        coruf_imp       = ls_coruf
        trans_autyp_imp = t490-autyp
        trans_typ_imp   = con_create
      IMPORTING
        coruf_exp       = ls_coruf
      EXCEPTIONS
        OTHERS          = 1.
    IF NOT sy-subrc IS INITIAL.
      MESSAGE i625(ru) WITH l_aufnr sy-tcode.
      EXIT.
    ENDIF.
  ENDIF.

  CALL FUNCTION 'CO_RU_GET_ORDER_DATA'
    EXPORTING
      aufnr_imp            = l_aufnr
      trtyp_imp            = con_create
    TABLES
      diatab_pos           = lt_dialog_tab
      diatab_sop           = lt_dialog_tab_sop
    EXCEPTIONS
      order_already_locked = 1
      OTHERS               = 2.
  IF sy-subrc = 1.
    MESSAGE ID sy-msgid TYPE 'S' NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    EXIT.
  ENDIF.

  IF ls_coruf IS INITIAL.
    ls_coruf-aufnr = l_aufnr.
    CALL FUNCTION 'CO_RU_TCORU_READ'
      EXPORTING
        auart_imp = caufvd-auart
        autyp_imp = caufvd-autyp
        werks_imp = caufvd-werks
      IMPORTING
        tcoru_exp = ls_tcoru
      EXCEPTIONS
        no_entry  = 1
        OTHERS    = 2.
    IF sy-subrc IS INITIAL.
      IF ls_tcoru-eruvg IS INITIAL.
        ls_coruf-offvg = con_yx.
      ENDIF.
      IF ls_tcoru-rufhg IS INITIAL.
        ls_coruf-rupfl = con_yx.
      ENDIF.
    ENDIF.
  ENDIF.

  CALL FUNCTION 'CO_RU_CLEAN_DIALOGTAB'
    EXPORTING
      is_coruf   = ls_coruf
    TABLES
      diatab_cnf = lt_dialog_tab_conf
      diatab_pos = lt_dialog_tab
      diatab_sop = lt_dialog_tab_sop.

  LOOP AT lt_dialog_tab INTO ls_dialog_wa.
    CLEAR: lt_values, lt_values_pi.
    CALL FUNCTION 'CO_RU_READ_AFVGD_WITH_INDEX'
      EXPORTING
        index_imp = ls_dialog_wa-index_plpo
      IMPORTING
        afvgd_exp = ls_afvgd.
    IF t490-autyp = con_order_type-process_order.
      MOVE-CORRESPONDING ls_afvgd TO lt_values_pi.
      APPEND lt_values_pi.
    ELSE.
      MOVE-CORRESPONDING ls_afvgd TO lt_values.
      APPEND lt_values.
    ENDIF.
  ENDLOOP.

  PERFORM fill_afvgd_data IN PROGRAM saplcorf USING ls_afvgd_sav.

  ls_dynpfld_mapping-fldname = 'F0002'.
  ls_dynpfld_mapping-dyfldname = 'AFRUD-APLFL'.
  APPEND ls_dynpfld_mapping TO lt_dynpfld_mapping.

  IF t490-autyp = con_order_type-process_order.
    CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
      EXPORTING
        retfield        = 'VORNR'
        dynpprog        = l_repid
        dynpnr          = l_dynnr
        dynprofield     = 'AFRUD-VORNR'
        value_org       = 'S'
      TABLES
        value_tab       = lt_values_pi
        dynpfld_mapping = lt_dynpfld_mapping
        return_tab      = lt_return_tab
      EXCEPTIONS
        OTHERS          = 0.
  ELSE.
    CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
      EXPORTING
        retfield        = 'VORNR'
        dynpprog        = l_repid
        dynpnr          = l_dynnr
        dynprofield     = 'AFRUD-VORNR'
        value_org       = 'S'
      TABLES
        value_tab       = lt_values
        dynpfld_mapping = lt_dynpfld_mapping
        return_tab      = lt_return_tab
      EXCEPTIONS
        OTHERS          = 0.
  ENDIF.
ENDFORM.                    " VAL_REQ_VORNR
*&---------------------------------------------------------------------*
*&      Form  CURSOR_FIELDS
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM cursor_fields .

  IF wa_tab-budat IS INITIAL.
    v_field = 'WA_TAB-BUDAT'.
    LEAVE TO SCREEN sy-dynnr.
  ENDIF.

  IF wa_tab-charg IS INITIAL.
    v_field = 'WA_TAB-CHARG'.
    LEAVE TO SCREEN sy-dynnr.
  ENDIF.


  IF wa_tab-vornr IS INITIAL.
    v_field = 'WA_TAB-VORNR'.
    LEAVE TO SCREEN sy-dynnr.
  ENDIF.

  IF wa_tab-menge IS INITIAL.
    v_field = 'WA_TAB-MENGE'.
    LEAVE TO SCREEN sy-dynnr.
  ENDIF.

  IF wa_tab-arbpl2 IS INITIAL.
    v_field = 'WA_TAB-ARBPL2'.
    LEAVE TO SCREEN sy-dynnr.
  ENDIF.

  IF wa_tab-logrp IS INITIAL.
    v_field = 'WA_TAB-LOGRP'.
    LEAVE TO SCREEN sy-dynnr.
  ENDIF.

  v_field = 'BTN_SAVE'.
ENDFORM.                    " CURSOR_FIELDS
*&---------------------------------------------------------------------*
*&      Form  BAPI_CO11N
*&---------------------------------------------------------------------*
*       Posts one operation confirmation for the batch on screen 0100.
*       Called from USER_COMMAND_0100 when the operator presses CREATE.
*----------------------------------------------------------------------*
FORM bapi_co11n .

  DATA: lv_werks TYPE werks_d.

  CLEAR: wa_hdr,  it_hdr[],
         wa_ret,  it_ret, it_ret[],
         it_ret2[],
         wa_dret, it_dret[],
         wa_mvt,  it_mvt[],
         wa_time, it_time[],
         wa_lnk,  it_lnk[],
         it_mess, it_mess[],
         v_failed.

*--- Which plant does this batch belong to?  The link table below decides
*--- whether this confirmation backflushes components, so a wrong or empty
*--- answer moves real stock.  ZPP_BATCHN is keyed BATCHNO + GJAHR and the
*--- 2012 migration left 192 rows under GJAHR '0000' with no order and no
*--- quantity, so they have to be excluded - and the read has to fail safe
*--- rather than fall through to "not 2002, therefore backflush".
  SELECT SINGLE werks
         FROM zpp_batchn
         INTO @lv_werks
         WHERE batchno EQ @wa_tab-charg AND
               gjahr   NE '0000'        AND
               delind  NE 'X'.
  IF sy-subrc NE 0 OR lv_werks IS INITIAL.
    MESSAGE e002(sy) WITH 'Plant not determined for batch - nothing posted'.
    RETURN.
  ENDIF.

*--- Authorisation.  Confirming posts activity and, outside plant 2002,
*--- goods movements.  Switch this on only once a role carrying
*--- Z_WIPBATCH (WERKS + ACTVT 01) is assigned to the confirming users -
*--- as of 30.08.2026 no role in KSD grants it, so an active check here
*--- refuses everyone without SAP_ALL.
*  AUTHORITY-CHECK OBJECT 'Z_WIPBATCH'
*    ID 'WERKS' FIELD lv_werks
*    ID 'ACTVT' FIELD c_actvt_create.
*  IF sy-subrc NE 0.
*    CLEAR v_msg.
*    CONCATENATE 'Not authorised to confirm in plant' lv_werks
*           INTO v_msg SEPARATED BY space.
*    MESSAGE e002(sy) WITH v_msg.
*    RETURN.
*  ENDIF.

  wa_time-orderid        = wa_tab-aufnr.
  wa_time-operation      = wa_tab-vornr.
  wa_time-postg_date     = wa_tab-budat.
  wa_time-yield          = wa_tab-menge.
  wa_time-conf_quan_unit = wa_tab-meinh.
  wa_time-work_cntr      = wa_tab-arbpl2.
  wa_time-wagegroup      = wa_tab-logrp.
*--- The batch travels in the confirmation text.  ZI_JobCardConfBase reads
*--- AFRU-LTXA1 back out of it, so this assignment is load-bearing for the
*--- Job Card Report - do not repurpose the field.
  wa_time-conf_text      = wa_tab-charg.

  APPEND wa_time TO it_time.

  IF lv_werks EQ c_plant_no_backflush.
*--- Plant 2002 confirms without backflush.  A business rule with no
*--- config behind it; if it ever has to vary by order type or cover a
*--- second plant, this IF is where it will be missed.
    wa_lnk-index_confirm   = 1.
    wa_lnk-index_gm_depend = 0.
    wa_lnk-index_goodsmov  = 0.
    APPEND wa_lnk TO it_lnk.
    CLEAR wa_lnk.
  ENDIF.

  CALL FUNCTION 'BAPI_PRODORDCONF_CREATE_TT'
    EXPORTING
      post_wrong_entries = '0'
    IMPORTING
      return             = it_ret
    TABLES
      timetickets        = it_time
      link_conf_goodsmov = it_lnk
      detail_return      = it_dret.

*--- Commit decision.  The old test was "commit if DETAIL_RETURN contains
*--- I/RU/100", which rolled back any success reporting a different message
*--- and committed any failure that happened to report RU100 alongside its
*--- errors.  RETURN was never looked at.  Test message types instead, and
*--- require the BAPI to have handed back a confirmation number.
  LOOP AT it_dret INTO wa_dret.
    IF wa_dret-type CA 'EAX'.
      v_failed = abap_true.
      EXIT.
    ENDIF.
  ENDLOOP.

  IF it_ret-type CA 'EAX'.
    v_failed = abap_true.
  ENDIF.

  READ TABLE it_time INTO wa_time INDEX 1.
  IF sy-subrc NE 0 OR wa_time-conf_no IS INITIAL.
    v_failed = abap_true.
  ENDIF.

  IF v_failed EQ abap_false.
    CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
      EXPORTING
        wait = c_wait.
    PERFORM clear_screen.
    wa_tab-budat = sy-datum.
  ELSE.
    CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.
  ENDIF.

*--- All four placeholders, not just v2 into v1.
  LOOP AT it_dret INTO wa_dret.
    it_mess-msgid = wa_dret-id.
    it_mess-msgty = wa_dret-type.
    it_mess-msgno = wa_dret-number.
    it_mess-msgv1 = wa_dret-message_v1.
    it_mess-msgv2 = wa_dret-message_v2.
    it_mess-msgv3 = wa_dret-message_v3.
    it_mess-msgv4 = wa_dret-message_v4.
    APPEND it_mess.
  ENDLOOP.

  IF NOT it_mess[] IS INITIAL.
    CALL FUNCTION 'C14Z_MESSAGES_SHOW_AS_POPUP'
      TABLES
        i_message_tab = it_mess.
  ENDIF.
ENDFORM.                    " BAPI_CO11N
*&---------------------------------------------------------------------*
*&      Form  CLEAR_SCREEN
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM clear_screen .
  CLEAR: wa_tab.
ENDFORM.                    " CLEAR_SCREEN
