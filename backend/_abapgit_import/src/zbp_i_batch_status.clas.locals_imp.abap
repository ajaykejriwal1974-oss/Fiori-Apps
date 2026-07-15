CLASS lhc_Batch DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS closeBatch FOR MODIFY
      IMPORTING keys FOR ACTION Batch~closeBatch RESULT result.
    METHODS deleteBatch FOR MODIFY
      IMPORTING keys FOR ACTION Batch~deleteBatch RESULT result.
ENDCLASS.

CLASS lhc_Batch IMPLEMENTATION.
  METHOD closeBatch.
    " Close the WIP batch on the custom table (replaces ZSOL_WIP_BATCH_CLOSE):
    " set CLOSED + who/when. ZPP_BATCHN is keyed by BATCHNO (+ GJAHR) - VERIFY the
    " year predicate for your data; here we close by batch number.
    LOOP AT keys INTO DATA(key).
      DATA(p) = key-%param.
      UPDATE zpp_batchn
        SET closed      = 'X',
            closed_by   = @sy-uname,
            closed_on   = @sy-datum,
            closed_time = @sy-uzeit
        WHERE batchno = @p-batch.
      IF sy-subrc = 0.
        CALL FUNCTION 'BAPI_TRANSACTION_COMMIT' EXPORTING wait = abap_true.
        APPEND VALUE #( %cid = key-%cid
                        %param = VALUE #( message = |Batch { p-batch } closed| ) ) TO result.
      ELSE.
        APPEND VALUE #( %cid = key-%cid
                        %param = VALUE #( message = |Batch { p-batch } not found in ZPP_BATCHN| ) ) TO result.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD deleteBatch.
    " Set the standard batch deletion flag via BAPI_BATCH_CHANGE.
    " VERIFY: MATERIAL (18 char) vs MATERIAL_LONG (40) for your release.
    LOOP AT keys INTO DATA(key).
      DATA(p) = key-%param.
      DATA lt_return TYPE STANDARD TABLE OF bapiret2.
      " Set the deletion flag on the attribute (+X) structures. The component is
      " DEL_FLAG on most releases; assign dynamically so either name works.
      DATA: ls_att  TYPE bapibatchatt,
            ls_attx TYPE bapibatchattx.
      FIELD-SYMBOLS <fs_flag> TYPE any.
      LOOP AT VALUE string_table( ( `DEL_FLAG` ) ( `DELETION_FLAG` ) ( `LVORM` ) ) INTO DATA(lv_comp).
        ASSIGN COMPONENT lv_comp OF STRUCTURE ls_att TO <fs_flag>.
        IF sy-subrc = 0.
          <fs_flag> = 'X'.
          ASSIGN COMPONENT lv_comp OF STRUCTURE ls_attx TO <fs_flag>.
          IF sy-subrc = 0. <fs_flag> = 'X'. ENDIF.
          EXIT.
        ENDIF.
      ENDLOOP.
      CALL FUNCTION 'BAPI_BATCH_CHANGE'
        EXPORTING material         = p-material
                  batch            = p-batch
                  plant            = p-plant
                  batchattributes  = ls_att
                  batchattributesx = ls_attx
        TABLES    return           = lt_return.
      DATA(lv_err) = REDUCE string( INIT s = ``
                       FOR r IN lt_return WHERE ( type = 'E' OR type = 'A' )
                       NEXT s = s && r-message && ` ` ).
      IF lv_err IS NOT INITIAL.
        CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.
        APPEND VALUE #( %cid = key-%cid %param = VALUE #( message = lv_err ) ) TO result.
      ELSE.
        CALL FUNCTION 'BAPI_TRANSACTION_COMMIT' EXPORTING wait = abap_true.
        APPEND VALUE #( %cid = key-%cid
                        %param = VALUE #( message = |Batch { p-batch } deletion flag set| ) ) TO result.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.
