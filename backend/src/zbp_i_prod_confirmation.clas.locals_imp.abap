CLASS lhc_zi_prod_confirmation DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS cancelconfirmations FOR MODIFY
      IMPORTING keys FOR ACTION ProdConfirmation~cancelConfirmations RESULT result.
ENDCLASS.

CLASS lhc_zi_prod_confirmation IMPLEMENTATION.
  METHOD cancelconfirmations.
    DATA: lv_msg    TYPE string,
          lv_conf   TYPE co_rueck,
          lv_cnt    TYPE co_rmzhl,
          lv_budat  TYPE budat,
          ls_return TYPE bapiret2,
          lt_detail TYPE STANDARD TABLE OF bapi_coru_return,
          ls_detail TYPE bapi_coru_return,
          lv_posted TYPE abap_bool.

    LOOP AT keys INTO DATA(ls_key).
      CLEAR: lv_msg, lv_posted.

      lv_budat = ls_key-%param-postingdate.
      IF lv_budat IS INITIAL.
        lv_budat = sy-datum.
      ENDIF.

      SPLIT ls_key-%param-confirmationlist AT ';' INTO TABLE DATA(lt_pairs).

      LOOP AT lt_pairs INTO DATA(lv_pair).
        CONDENSE lv_pair.
        IF lv_pair IS INITIAL.
          CONTINUE.
        ENDIF.
        SPLIT lv_pair AT '=' INTO DATA(lv_rueck) DATA(lv_rmzhl).
        CONDENSE: lv_rueck, lv_rmzhl.
        lv_conf = |{ lv_rueck ALPHA = IN }|.
        lv_cnt  = lv_rmzhl.

        " Guard: the confirmation must exist, must not be a reversal
        " document itself, and must not already be cancelled.
        SELECT SINGLE stzhl, stokz FROM afru
          WHERE rueck = @lv_conf AND rmzhl = @lv_cnt
          INTO @DATA(ls_afru).
        IF sy-subrc <> 0.
          lv_msg = |{ lv_msg }{ lv_rueck }/{ lv_rmzhl }: confirmation not found. |.
          CONTINUE.
        ENDIF.
        IF ls_afru-stokz = 'X'.
          lv_msg = |{ lv_msg }{ lv_rueck }/{ lv_rmzhl }: this is a reversal document, skipped. |.
          CONTINUE.
        ENDIF.
        IF ls_afru-stzhl <> 0.
          lv_msg = |{ lv_msg }{ lv_rueck }/{ lv_rmzhl }: already cancelled. |.
          CONTINUE.
        ENDIF.

        CLEAR: ls_return, lt_detail.
        " update-task BAPI -> separate LUW via aRFC.
        CALL FUNCTION 'BAPI_PRODORDCONF_CANCEL' DESTINATION 'NONE'
          EXPORTING
            confirmation        = lv_conf
            confirmationcounter = lv_cnt
            postg_date          = lv_budat
          IMPORTING
            return              = ls_return
          TABLES
            detail_return       = lt_detail
          EXCEPTIONS OTHERS     = 0.

        IF ls_return-type CA 'EA'.
          lv_msg = |{ lv_msg }{ lv_rueck }/{ lv_rmzhl }: { ls_return-message }. |.
          CONTINUE.
        ENDIF.

        READ TABLE lt_detail INTO ls_detail WITH KEY type = 'E'.
        IF sy-subrc = 0.
          lv_msg = |{ lv_msg }{ lv_rueck }/{ lv_rmzhl }: { ls_detail-message }. |.
          CONTINUE.
        ENDIF.

        lv_posted = abap_true.
        lv_msg = |{ lv_msg }{ lv_rueck }/{ lv_rmzhl }: confirmation cancelled. |.
      ENDLOOP.

      IF lv_posted = abap_true.
        CALL FUNCTION 'BAPI_TRANSACTION_COMMIT' DESTINATION 'NONE'
          EXPORTING wait = 'X' EXCEPTIONS OTHERS = 0.
      ENDIF.
      IF lv_msg IS INITIAL.
        lv_msg = |No confirmation supplied.|.
      ENDIF.
      INSERT VALUE #( %cid = ls_key-%cid %param-message = lv_msg ) INTO TABLE result.
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.

CLASS lsc_zi_prod_confirmation DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PROTECTED SECTION.
    METHODS save REDEFINITION.
ENDCLASS.

CLASS lsc_zi_prod_confirmation IMPLEMENTATION.
  METHOD save.
  ENDMETHOD.
ENDCLASS.
