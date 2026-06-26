CLASS lhc_InboundHu DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS postInboundGr FOR MODIFY
      IMPORTING keys FOR ACTION InboundHu~postInboundGr RESULT result.
ENDCLASS.

CLASS lhc_InboundHu IMPLEMENTATION.
  METHOD postInboundGr.
    LOOP AT keys INTO DATA(key).
      DATA(ls_param) = key-%param.
      " TODO: post the inbound-delivery goods receipt for the listed HUs (BAPI_INB_DELIVERY_CONFIRM_DEC / WS_DELIVERY_UPDATE).
      APPEND VALUE #( %cid = key-%cid
                      %param = VALUE #( message = 'TODO: wire BAPI_INB_DELIVERY_CONFIRM_DEC' ) ) TO result.
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.
