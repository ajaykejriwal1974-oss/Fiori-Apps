 FUNCTION z_kgpl_batch_maintain.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(IV_MATERIAL) TYPE  MATNR
*"     VALUE(IV_BATCH) TYPE  CHARG_D
*"     VALUE(IV_PLANT) TYPE  WERKS_D
*"     VALUE(IV_MODE) TYPE  CHAR1
*"----------------------------------------------------------------------
   DATA: lv_matnr  TYPE bapibatchkey-material,
        ls_att    TYPE bapibatchatt,
        ls_attx   TYPE bapibatchattx,
        lt_return TYPE STANDARD TABLE OF bapiret2.

  lv_matnr = iv_material.
  CASE iv_mode.
    WHEN 'R'.
      ls_att-available  = abap_true.
      ls_attx-available = abap_true.
    WHEN 'D'.
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
