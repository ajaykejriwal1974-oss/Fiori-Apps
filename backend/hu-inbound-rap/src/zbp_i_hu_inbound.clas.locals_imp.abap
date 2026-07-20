CLASS lhc_zi_hu_inbound DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS postinboundgr FOR MODIFY
      IMPORTING keys FOR ACTION InboundHu~postInboundGr RESULT result.
ENDCLASS.

CLASS lhc_zi_hu_inbound IMPLEMENTATION.
  METHOD postinboundgr.
    DATA: ls_hdr_data TYPE bapiibdlvhdrchg,
          ls_hdr_ctrl TYPE bapiibdlvhdrctrlchg,
          lv_delivery TYPE bapiibdlvhdrchg-deliv_numb,
          lt_return   TYPE STANDARD TABLE OF bapiret2.

    LOOP AT keys INTO DATA(ls_key).
      CLEAR: lt_return, ls_hdr_data, ls_hdr_ctrl.
      lv_delivery = |{ ls_key-%param-InboundDelivery ALPHA = IN }|.
      ls_hdr_data-deliv_numb = lv_delivery.
      ls_hdr_ctrl-deliv_numb = lv_delivery.

      CALL FUNCTION 'BAPI_INB_DELIVERY_CONFIRM_DEC'
        EXPORTING  header_data    = ls_hdr_data
                   header_control = ls_hdr_ctrl
                   delivery       = lv_delivery
        TABLES     return         = lt_return.

      READ TABLE lt_return INTO DATA(ls_err) WITH KEY type = 'E'.
      IF sy-subrc = 0.
        INSERT VALUE #( %cid = ls_key-%cid %param-message = ls_err-message ) INTO TABLE result.
      ELSE.
        INSERT VALUE #( %cid = ls_key-%cid
          %param-message = |Goods receipt posted for inbound delivery { ls_key-%param-InboundDelivery }.| )
          INTO TABLE result.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.

CLASS lsc_zi_hu_inbound DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PROTECTED SECTION.
    METHODS save REDEFINITION.
ENDCLASS.

CLASS lsc_zi_hu_inbound IMPLEMENTATION.
  METHOD save.
  ENDMETHOD.
ENDCLASS.
