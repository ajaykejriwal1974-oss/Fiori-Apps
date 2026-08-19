FUNCTION Z_KGPL_INB_DELIVERY_GR.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(IV_DELIVERY) TYPE  VBELN_VL
*"----------------------------------------------------------------------
  DATA: ls_hdr_data TYPE bapiibdlvhdrcon,
        ls_hdr_ctrl TYPE bapiibdlvhdrctrlcon,
        lt_return   TYPE STANDARD TABLE OF bapiret2.

  ls_hdr_data-deliv_numb = iv_delivery.
  ls_hdr_ctrl-deliv_numb = iv_delivery.

  CALL FUNCTION 'BAPI_INB_DELIVERY_CONFIRM_DEC'
    EXPORTING header_data    = ls_hdr_data
              header_control = ls_hdr_ctrl
              delivery       = iv_delivery
    TABLES    return         = lt_return.

  READ TABLE lt_return TRANSPORTING NO FIELDS WITH KEY type = 'E'.
  IF sy-subrc = 0.
    CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.
  ELSE.
    CALL FUNCTION 'BAPI_TRANSACTION_COMMIT' EXPORTING wait = abap_true.
  ENDIF.




ENDFUNCTION.
