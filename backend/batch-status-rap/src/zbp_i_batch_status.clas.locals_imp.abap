CLASS lhc_zi_batch_status DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS closebatch  FOR MODIFY IMPORTING keys FOR ACTION Batch~closeBatch  RESULT result.
    METHODS deletebatch FOR MODIFY IMPORTING keys FOR ACTION Batch~deleteBatch RESULT result.
ENDCLASS.

CLASS lhc_zi_batch_status IMPLEMENTATION.
  " NOTE: the batch-maintenance BAPIs (BAPI_BATCH_RESTRICT/_DELETE/_CHANGE) either
  " have inconsistent interface metadata on this system or do an internal COMMIT WORK,
  " which is forbidden inside a RAP behavior. So the batch flags are set by a direct
  " MCHA update (no COMMIT - the RAP runtime commits). This bypasses batch change
  " documents / status management; upgrade to a decoupled (bgRFC) batch call if that
  " is required. VERIFY the ZUSTD 'restricted' value against the KGPL convention.
  METHOD closebatch.
    DATA: lv_matnr TYPE mcha-matnr,
          lv_werks TYPE mcha-werks,
          lv_charg TYPE mcha-charg.
    LOOP AT keys INTO DATA(ls_key).
      lv_matnr = ls_key-%param-Material.
      lv_werks = ls_key-%param-Plant.
      lv_charg = ls_key-%param-Batch.
      UPDATE mcha SET zustd = 'X'                       " batch status -> restricted
        WHERE matnr = @lv_matnr AND werks = @lv_werks AND charg = @lv_charg.
      INSERT VALUE #( %cid = ls_key-%cid
        %param-message = COND #( WHEN sy-subrc = 0
                                 THEN |Batch { ls_key-%param-Batch } closed (marked restricted).|
                                 ELSE |Batch { ls_key-%param-Batch } not found at plant { ls_key-%param-Plant }.| ) )
        INTO TABLE result.
    ENDLOOP.
  ENDMETHOD.

  METHOD deletebatch.
    DATA: lv_matnr TYPE mcha-matnr,
          lv_werks TYPE mcha-werks,
          lv_charg TYPE mcha-charg.
    LOOP AT keys INTO DATA(ls_key).
      lv_matnr = ls_key-%param-Material.
      lv_werks = ls_key-%param-Plant.
      lv_charg = ls_key-%param-Batch.
      UPDATE mcha SET lvorm = 'X'                       " deletion flag
        WHERE matnr = @lv_matnr AND werks = @lv_werks AND charg = @lv_charg.
      INSERT VALUE #( %cid = ls_key-%cid
        %param-message = COND #( WHEN sy-subrc = 0
                                 THEN |Batch { ls_key-%param-Batch } flagged for deletion.|
                                 ELSE |Batch { ls_key-%param-Batch } not found at plant { ls_key-%param-Plant }.| ) )
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
