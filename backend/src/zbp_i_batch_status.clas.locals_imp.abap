CLASS lcl_batch_buffer DEFINITION.
  PUBLIC SECTION.
    TYPES: BEGIN OF ty_batch,
             material TYPE matnr,
             batch    TYPE charg_d,
             plant    TYPE werks_d,
             mode     TYPE c LENGTH 1,
           END OF ty_batch.
    CLASS-DATA gt_batches TYPE STANDARD TABLE OF ty_batch WITH EMPTY KEY.
ENDCLASS.

CLASS lhc_zi_batch_status DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS closebatch  FOR MODIFY IMPORTING keys FOR ACTION Batch~closeBatch  RESULT result.
    METHODS deletebatch FOR MODIFY IMPORTING keys FOR ACTION Batch~deleteBatch RESULT result.
ENDCLASS.

CLASS lhc_zi_batch_status IMPLEMENTATION.
  METHOD closebatch.
    LOOP AT keys INTO DATA(ls_key).
      APPEND VALUE #( material = ls_key-%param-Material
                      batch    = ls_key-%param-Batch
                      plant    = ls_key-%param-Plant
                      mode     = 'R' ) TO lcl_batch_buffer=>gt_batches.
      INSERT VALUE #( %cid = ls_key-%cid
        %param-message = |Batch { ls_key-%param-Batch } queued to be restricted (on commit).| )
        INTO TABLE result.
    ENDLOOP.
  ENDMETHOD.

  METHOD deletebatch.
    LOOP AT keys INTO DATA(ls_key).
      APPEND VALUE #( material = ls_key-%param-Material
                      batch    = ls_key-%param-Batch
                      plant    = ls_key-%param-Plant
                      mode     = 'D' ) TO lcl_batch_buffer=>gt_batches.
      INSERT VALUE #( %cid = ls_key-%cid
        %param-message = |Batch { ls_key-%param-Batch } queued for deletion (on commit).| )
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
    LOOP AT lcl_batch_buffer=>gt_batches INTO DATA(ls_b).
      CALL FUNCTION 'Z_KGPL_BATCH_MAINTAIN'
        IN BACKGROUND TASK
        DESTINATION 'NONE'
        EXPORTING iv_material = ls_b-material
                  iv_batch    = ls_b-batch
                  iv_plant    = ls_b-plant
                  iv_mode     = ls_b-mode.
    ENDLOOP.
    CLEAR lcl_batch_buffer=>gt_batches.
  ENDMETHOD.
ENDCLASS.
