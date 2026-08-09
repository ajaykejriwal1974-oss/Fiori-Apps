CLASS lhc_Batch DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS closeBatch FOR MODIFY
      IMPORTING keys FOR ACTION Batch~closeBatch RESULT result.
    METHODS deleteBatch FOR MODIFY
      IMPORTING keys FOR ACTION Batch~deleteBatch RESULT result.
ENDCLASS.

CLASS lhc_Batch IMPLEMENTATION.
  METHOD closeBatch.
    " Close the WIP batches on the custom table (replaces ZSOL_WIP_BATCH_CLOSE):
    " set CLOSED + who/when. ZPP_BATCHN is keyed by BATCHNO (+ GJAHR) - VERIFY the
    " year predicate for your data; here we close by batch number.
    " COMPOSITION action (ZD_BatchClose._Item): the worklist's whole selection arrives
    " in ONE call and commits ONCE - previously one HTTP round trip + one synchronous
    " COMMIT WORK per selected batch.
    LOOP AT keys INTO DATA(key).
      DATA(lt_items) = key-%param-_item.
      IF lt_items IS INITIAL.
        APPEND VALUE #( %cid = key-%cid %param-message = 'No batches selected' ) TO result.
        CONTINUE.
      ENDIF.
      DATA lv_ok   TYPE i.
      DATA lt_miss TYPE STANDARD TABLE OF string WITH EMPTY KEY.
      CLEAR: lv_ok, lt_miss.
      LOOP AT lt_items INTO DATA(it).
        UPDATE zpp_batchn
          SET closed      = 'X',
              closed_by   = @sy-uname,
              closed_on   = @sy-datum,
              closed_time = @sy-uzeit
          WHERE batchno = @it-batch.
        IF sy-subrc = 0.
          lv_ok += 1.
        ELSE.
          APPEND |{ it-batch }| TO lt_miss.
        ENDIF.
      ENDLOOP.
      COMMIT WORK.   " once per action call, not per batch
      APPEND VALUE #( %cid = key-%cid
                      %param = VALUE #( message = |{ lv_ok } batch(es) closed| &&
                        COND #( WHEN lt_miss IS NOT INITIAL
                                THEN |; not found in ZPP_BATCHN: { concat_lines_of( table = lt_miss sep = `, ` ) }|
                                ELSE `` ) ) ) TO result.
    ENDLOOP.
  ENDMETHOD.

  METHOD deleteBatch.
    " Set the standard batch deletion flag via BAPI_BATCH_CHANGE.
    " VERIFY: MATERIAL (18 char) vs MATERIAL_LONG (40) for your release.
    " COMPOSITION action (ZD_BatchDelete._Item): all selected batches in ONE call,
    " all-or-nothing - any error rolls the whole selection back, else ONE commit.
    LOOP AT keys INTO DATA(key).
      DATA(lt_del) = key-%param-_item.
      IF lt_del IS INITIAL.
        APPEND VALUE #( %cid = key-%cid %param-message = 'No batches selected' ) TO result.
        CONTINUE.
      ENDIF.
      DATA lt_return TYPE STANDARD TABLE OF bapiret2.
      DATA lt_errs   TYPE STANDARD TABLE OF bapiret2.
      DATA ls_ret    TYPE bapiret2.
      CLEAR: lt_return, lt_errs.
      LOOP AT lt_del INTO DATA(ld).
        CLEAR lt_return.
        CALL FUNCTION 'BAPI_BATCH_CHANGE'
          EXPORTING material           = ld-material
                    batch              = ld-batch
                    plant              = ld-plant
                    batchattributes    = VALUE bapibatchatt( deletion_flg = 'X' )
                    batchcontrolfields = VALUE bapibatchctrl( deletion_flg = 'X' )
          TABLES    return             = lt_return.
        LOOP AT lt_return INTO ls_ret WHERE type = 'E' OR type = 'A'.
          APPEND ls_ret TO lt_errs.
        ENDLOOP.
      ENDLOOP.
      DATA(lv_err) = REDUCE string( INIT s = ``
                       FOR r IN lt_errs
                       NEXT s = s && r-message && ` ` ).
      IF lv_err IS NOT INITIAL.
        CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.
        APPEND VALUE #( %cid = key-%cid %param = VALUE #( message = lv_err ) ) TO result.
      ELSE.
        CALL FUNCTION 'BAPI_TRANSACTION_COMMIT' EXPORTING wait = abap_true.
        APPEND VALUE #( %cid = key-%cid
                        %param = VALUE #( message = |{ lines( lt_del ) } batch(es): deletion flag set| ) ) TO result.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.
