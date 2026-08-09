*"----------------------------------------------------------------------
*" Wrapper FM for decoupled batch maintenance (see zbp_i_batch_status).
*"
*" Create in SE37 / ADT as an RFC-ENABLED function module in a Z function
*" group (e.g. ZKGPL_HU). Called as a tRFC unit from ZBP_I_BATCH_STATUS's
*" save() so BAPI_BATCH_CHANGE (which does an internal COMMIT WORK) runs in
*" its OWN LUW, not inside the RAP behavior. This gives proper batch change
*" documents / status management / stock reclassification.
*"
*" Function builder settings:
*"   - Processing type: Remote-Enabled Module
*"   - Import (all Pass Value):
*"       IV_MATERIAL TYPE MATNR
*"       IV_BATCH    TYPE CHARG_D
*"       IV_PLANT    TYPE WERKS_D
*"       IV_MODE     TYPE CHAR1        ( 'R' = restrict, 'D' = set deletion flag )
*"----------------------------------------------------------------------
FUNCTION z_kgpl_batch_maintain.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(IV_MATERIAL) TYPE MATNR
*"     VALUE(IV_BATCH) TYPE CHARG_D
*"     VALUE(IV_PLANT) TYPE WERKS_D
*"     VALUE(IV_MODE) TYPE CHAR1
*"----------------------------------------------------------------------
  DATA: lv_matnr  TYPE bapibatchkey-material,   " CHAR18 - matches the BAPI param
        ls_att    TYPE bapibatchatt,
        ls_attx   TYPE bapibatchattx,
        lt_return TYPE STANDARD TABLE OF bapiret2.

  lv_matnr = iv_material.
  CASE iv_mode.
    WHEN 'R'.                                  " put batch into restricted-use stock
      ls_att-available  = abap_true.
      ls_attx-available = abap_true.
    WHEN 'D'.                                  " set deletion flag
      ls_att-del_flag  = abap_true.
      ls_attx-del_flag = abap_true.
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
