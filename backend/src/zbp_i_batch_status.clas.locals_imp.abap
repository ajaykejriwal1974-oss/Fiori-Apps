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

  " closeBatch is switched off on purpose.
  "
  " It used to queue mode 'R' into Z_KGPL_BATCH_MAINTAIN, which set
  " BAPIBATCHATT-AVAILABLE = abap_true and called BAPI_BATCH_CHANGE, and told
  " the user the batch was "queued to be restricted". AVAILABLE is data element
  " VERAB, "Availability date" - a DATS field, not a status flag. The call wrote
  " the character 'X' into a date and closed, restricted and changed nothing.
  "
  " Checked before removing it (2026-08-29): no MCHA row in KSD carries a
  " non-initial VERAB, so it had never run - the UI was sending an `_Item`
  " parameter the service does not declare, and every call failed first.
  "
  " Deciding what closing an MCHA batch should mean here is a business call, not
  " a code fix: restricted-use stock lives on MCHB, not on the batch master, and
  " BAPIBATCHATT in this release cannot set it. Until that is settled the action
  " refuses rather than posting something arbitrary. Closing a dyeing WIP batch
  " is a different thing entirely and belongs to the WIP Batch Close app.
  METHOD closebatch.
    LOOP AT keys INTO DATA(ls_key).
      INSERT VALUE #( %cid = ls_key-%cid
        %param-message = |Close Batch is not implemented. It wrote 'X' into the batch availability | &&
                         |date (VERAB) instead of closing anything, so it has been switched off. | &&
                         |To close a dyeing WIP batch, use the WIP Batch Close app.| )
        INTO TABLE result.
    ENDLOOP.
  ENDMETHOD.

  " Delete is sound: mode 'D' sets BAPIBATCHATT-DEL_FLAG, data element LVORM,
  " which is the batch deletion indicator it looks like.
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
    " Still IN BACKGROUND TASK: a BAPI in the RAP save sequence has to be. The
    " consequence is that BAPI errors never reach the screen, so the message
    " above says "queued", not "done".
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
