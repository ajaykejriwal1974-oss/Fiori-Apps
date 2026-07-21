*"----------------------------------------------------------------------
*" Wrapper FM for the decoupled inbound-delivery GR (see zbp_i_hu_inbound).
*"
*" Create in SE37 / ADT as an RFC-ENABLED function module in a Z function
*" group (e.g. ZKGPL_HU). Called as a tRFC unit from ZBP_I_HU_INBOUND's
*" save() so the delivery PGR (which commits + raises RAP entity events)
*" runs in its OWN LUW, not inside the RAP behavior.
*"
*" Function builder settings:
*"   - Processing type: Remote-Enabled Module
*"   - Import: IV_DELIVERY  TYPE VBELN_VL  (pass value)
*"----------------------------------------------------------------------
FUNCTION z_kgpl_inb_delivery_gr.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(IV_DELIVERY) TYPE VBELN_VL
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
    " optional: log lt_return errors to a Z-log / application log here
  ELSE.
    CALL FUNCTION 'BAPI_TRANSACTION_COMMIT' EXPORTING wait = abap_true.
  ENDIF.
ENDFUNCTION.
