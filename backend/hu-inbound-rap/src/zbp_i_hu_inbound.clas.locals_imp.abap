CLASS lhc_zi_hu_inbound DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS postinboundgr FOR MODIFY
      IMPORTING keys FOR ACTION InboundHu~postInboundGr RESULT result.
ENDCLASS.

CLASS lhc_zi_hu_inbound IMPLEMENTATION.
  METHOD postinboundgr.
    " BAPI_INB_DELIVERY_CONFIRM_DEC does a full delivery save (posts GR, commits,
    " RAISEs RAP entity events on the inbound-delivery BO) -> illegal inside a RAP
    " action (BEHAVIOR_ILLEGAL_STATEMENT). The GR must run in a SEPARATE LUW
    " (bgRFC unit / background job, or the delivery's own released RAP action).
    " Placeholder until that decoupled path is built.
    LOOP AT keys INTO DATA(ls_key).
      INSERT VALUE #( %cid = ls_key-%cid
        %param-message = |Inbound GR for delivery { ls_key-%param-InboundDelivery } must be posted in a separate LUW (deferred).| )
        INTO TABLE result.
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
