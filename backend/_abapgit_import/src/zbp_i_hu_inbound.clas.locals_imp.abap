CLASS lhc_InboundHu DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS postInboundGr FOR MODIFY
      IMPORTING keys FOR ACTION InboundHu~postInboundGr RESULT result.
ENDCLASS.

CLASS lhc_InboundHu IMPLEMENTATION.
  METHOD postInboundGr.
    " VERIFY: BAPI_INB_DELIVERY_CONFIRM_DEC header/control structure names vary by
    " release; post_gi_flg drives the goods-receipt posting for the inbound delivery.
    LOOP AT keys INTO DATA(key).
      DATA(h) = key-%param.
      DATA lt_return TYPE STANDARD TABLE OF bapiret2.

      CALL FUNCTION 'BAPI_INB_DELIVERY_CONFIRM_DEC'
        EXPORTING header_data    = VALUE bapiibdlvhdrcon( deliv_numb = h-inbounddelivery )
                  header_control = VALUE bapiibdlvhdrctrlcon( deliv_numb = h-inbounddelivery
                                                              post_gi_flg = 'X' )
                  delivery       = h-inbounddelivery
        TABLES    return         = lt_return.

      DATA(lv_err) = REDUCE string( INIT s = ``
                       FOR r IN lt_return WHERE ( type = 'E' OR type = 'A' )
                       NEXT s = s && r-message && ` ` ).
      IF lv_err IS NOT INITIAL.
        CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.
        APPEND VALUE #( %cid = key-%cid %param = VALUE #( message = lv_err ) ) TO result.
      ELSE.
        CALL FUNCTION 'BAPI_TRANSACTION_COMMIT' EXPORTING wait = abap_true.
        APPEND VALUE #( %cid = key-%cid
                        %param = VALUE #( message = |Inbound GR posted for delivery { h-inbounddelivery }| ) ) TO result.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.
