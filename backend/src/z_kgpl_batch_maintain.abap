FUNCTION z_kgpl_batch_maintain
  IMPORTING
    VALUE(iv_material) TYPE matnr
    VALUE(iv_batch) TYPE charg_d
    VALUE(iv_plant) TYPE werks_d
    VALUE(iv_mode) TYPE char1.

  DATA: lv_matnr  TYPE bapibatchkey-material,
        ls_att    TYPE bapibatchatt,
        ls_attx   TYPE bapibatchattx,
        lt_return TYPE STANDARD TABLE OF bapiret2.

  lv_matnr = iv_material.

  CASE iv_mode.
*   Mode 'R' used to set BAPIBATCHATT-AVAILABLE = abap_true and was reported to
*   the user as "queued to be restricted". AVAILABLE is data element VERAB,
*   "Availability date" - a DATS field, not a status flag - so the call wrote
*   the character 'X' into a date and restricted nothing. Removed 2026-08-30.
*   Checked first: no MCHA row in KSD carried a non-initial VERAB, so it had
*   never actually run. Close Batch in the app now refuses instead of calling
*   this, until someone decides what closing an MCHA batch should mean.
    WHEN 'D'.
      ls_att-del_flag  = abap_true.
      ls_attx-del_flag = abap_true.
    WHEN OTHERS.
*     Do not post something arbitrary for a mode nobody defined.
      RETURN.
  ENDCASE.

  CALL FUNCTION 'BAPI_BATCH_CHANGE'
    EXPORTING material         = lv_matnr
              batch            = iv_batch
              plant            = iv_plant
              batchattributes  = ls_att
              batchattributesx = ls_attx
    TABLES    return           = lt_return.

  READ TABLE lt_return TRANSPORTING NO FIELDS WITH KEY type = 'E'.
  IF sy-subrc = 0.
    CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.
  ELSE.
    CALL FUNCTION 'BAPI_TRANSACTION_COMMIT' EXPORTING wait = abap_true.
  ENDIF.

ENDFUNCTION.
