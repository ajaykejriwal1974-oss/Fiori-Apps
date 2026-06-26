CLASS lhc_Batch DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS closeBatch FOR MODIFY
      IMPORTING keys FOR ACTION Batch~closeBatch RESULT result.
    METHODS deleteBatch FOR MODIFY
      IMPORTING keys FOR ACTION Batch~deleteBatch RESULT result.
ENDCLASS.

CLASS lhc_Batch IMPLEMENTATION.
  METHOD closeBatch.
    LOOP AT keys INTO DATA(key).
      DATA(ls_param) = key-%param.
      " TODO: set the batch to a restricted/closed status via BAPI_BATCH_CHANGE.
      APPEND VALUE #( %cid = key-%cid
                      %param = VALUE #( message = 'TODO: wire BAPI_BATCH_CHANGE' ) ) TO result.
    ENDLOOP.
  ENDMETHOD.
  METHOD deleteBatch.
    LOOP AT keys INTO DATA(key).
      DATA(ls_param) = key-%param.
      " TODO: set the batch deletion flag via BAPI_BATCH_CHANGE (deletion indicator).
      APPEND VALUE #( %cid = key-%cid
                      %param = VALUE #( message = 'TODO: wire BAPI_BATCH_CHANGE' ) ) TO result.
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.
