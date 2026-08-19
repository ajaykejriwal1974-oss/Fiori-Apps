CLASS lhc_zi_wip_batch_mgmt DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS closebatches FOR MODIFY
      IMPORTING keys FOR ACTION WipBatch~closeBatches RESULT result.
    METHODS reopenbatches FOR MODIFY
      IMPORTING keys FOR ACTION WipBatch~reopenBatches RESULT result.

    " Shared implementation. iv_close = abap_true -> set CLOSED = 'X',
    " abap_false -> clear it. Returns the per-row message text.
    METHODS set_closed
      IMPORTING iv_list         TYPE string
                iv_close        TYPE abap_bool
      RETURNING VALUE(rv_msg)   TYPE string.
ENDCLASS.

CLASS lhc_zi_wip_batch_mgmt IMPLEMENTATION.

  METHOD set_closed.
    DATA: lv_batch TYPE zpp_batchn-batchno,
          lv_year  TYPE zpp_batchn-gjahr,
          lv_hit   TYPE abap_bool.

    SPLIT iv_list AT ';' INTO TABLE DATA(lt_pairs).

    LOOP AT lt_pairs INTO DATA(lv_pair).
      CONDENSE lv_pair.
      IF lv_pair IS INITIAL.
        CONTINUE.
      ENDIF.
      SPLIT lv_pair AT '=' INTO DATA(lv_b) DATA(lv_y).
      CONDENSE: lv_b, lv_y.
      lv_batch = lv_b.
      lv_year  = lv_y.

      SELECT SINGLE closed, assigned FROM zpp_batchn
        WHERE batchno = @lv_batch AND gjahr = @lv_year
        INTO @DATA(ls_bat).
      IF sy-subrc <> 0.
        rv_msg = |{ rv_msg }{ lv_b }: batch not found. |.
        CONTINUE.
      ENDIF.

      IF iv_close = abap_true AND ls_bat-closed = 'X'.
        rv_msg = |{ rv_msg }{ lv_b }: already closed. |.
        CONTINUE.
      ENDIF.
      IF iv_close = abap_false AND ls_bat-closed <> 'X'.
        rv_msg = |{ rv_msg }{ lv_b }: already open. |.
        CONTINUE.
      ENDIF.

      IF iv_close = abap_true.
        UPDATE zpp_batchn SET closed = 'X'
          WHERE batchno = @lv_batch AND gjahr = @lv_year.
      ELSE.
        UPDATE zpp_batchn SET closed = ' '
          WHERE batchno = @lv_batch AND gjahr = @lv_year.
      ENDIF.

      IF sy-subrc = 0.
        lv_hit = abap_true.
        IF iv_close = abap_true.
          rv_msg = |{ rv_msg }{ lv_b }: closed. |.
        ELSE.
          rv_msg = |{ rv_msg }{ lv_b }: reopened. |.
        ENDIF.
      ELSE.
        rv_msg = |{ rv_msg }{ lv_b }: update failed. |.
      ENDIF.
    ENDLOOP.

    IF lv_hit = abap_true.
      COMMIT WORK AND WAIT.
    ENDIF.
    IF rv_msg IS INITIAL.
      rv_msg = |No batch supplied.|.
    ENDIF.
  ENDMETHOD.

  METHOD closebatches.
    LOOP AT keys INTO DATA(ls_key).
      DATA(lv_msg) = set_closed(
        iv_list  = CONV string( ls_key-%param-batchlist )
        iv_close = abap_true ).
      INSERT VALUE #( %cid = ls_key-%cid %param-message = lv_msg ) INTO TABLE result.
    ENDLOOP.
  ENDMETHOD.

  METHOD reopenbatches.
    LOOP AT keys INTO DATA(ls_key).
      " Reopening is the destructive direction - it lets a confirmation be
      " cancelled or deducted afterwards, so a reason is mandatory.
      IF ls_key-%param-reason IS INITIAL.
        INSERT VALUE #( %cid = ls_key-%cid
                        %param-message = |A reason is required to reopen a batch.| )
               INTO TABLE result.
        CONTINUE.
      ENDIF.
      DATA(lv_msg) = set_closed(
        iv_list  = CONV string( ls_key-%param-batchlist )
        iv_close = abap_false ).
      INSERT VALUE #( %cid = ls_key-%cid
                      %param-message = |{ lv_msg }Reason: { ls_key-%param-reason }| )
             INTO TABLE result.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.

CLASS lsc_zi_wip_batch_mgmt DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PROTECTED SECTION.
    METHODS save REDEFINITION.
ENDCLASS.

CLASS lsc_zi_wip_batch_mgmt IMPLEMENTATION.
  METHOD save.
  ENDMETHOD.
ENDCLASS.
