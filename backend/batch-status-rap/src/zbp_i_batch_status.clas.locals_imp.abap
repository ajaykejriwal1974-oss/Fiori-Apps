CLASS lhc_zi_batch_status DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS closebatch  FOR MODIFY IMPORTING keys FOR ACTION Batch~closeBatch  RESULT result.
    METHODS deletebatch FOR MODIFY IMPORTING keys FOR ACTION Batch~deleteBatch RESULT result.
ENDCLASS.

CLASS lhc_zi_batch_status IMPLEMENTATION.
  METHOD closebatch.
    DATA ls_return TYPE bapiret2.
    LOOP AT keys INTO DATA(ls_key).
      CLEAR ls_return.
      CALL FUNCTION 'BAPI_BATCH_RESTRICT'
        EXPORTING material = ls_key-%param-Material
                  batch    = ls_key-%param-Batch
                  plant    = ls_key-%param-Plant
        IMPORTING return   = ls_return.
      INSERT VALUE #( %cid = ls_key-%cid
        %param-message = COND #( WHEN ls_return-type CA 'EAX'
                                 THEN ls_return-message
                                 ELSE |Batch { ls_key-%param-Batch } closed (restricted).| ) )
        INTO TABLE result.
    ENDLOOP.
  ENDMETHOD.

  METHOD deletebatch.
    DATA ls_return TYPE bapiret2.
    LOOP AT keys INTO DATA(ls_key).
      CLEAR ls_return.
      CALL FUNCTION 'BAPI_BATCH_DELETE'
        EXPORTING material = ls_key-%param-Material
                  batch    = ls_key-%param-Batch
                  plant    = ls_key-%param-Plant
        IMPORTING return   = ls_return.
      INSERT VALUE #( %cid = ls_key-%cid
        %param-message = COND #( WHEN ls_return-type CA 'EAX'
                                 THEN ls_return-message
                                 ELSE |Batch { ls_key-%param-Batch } flagged for deletion.| ) )
        INTO TABLE result.
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.

CLASS lsc_zi_batch_status DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PROTECTED SECTION.
    METHODS save REDEFINITION.
ENDCLASS.

CLASS lsc_zi_batch_status IMPLEMENTATION.
  METHOD save.
  ENDMETHOD.
ENDCLASS.
