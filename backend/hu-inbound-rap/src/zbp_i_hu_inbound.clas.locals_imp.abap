CLASS lcl_inb_buffer DEFINITION.
  PUBLIC SECTION.
    CLASS-DATA gt_deliveries TYPE STANDARD TABLE OF vbeln_vl WITH EMPTY KEY.
ENDCLASS.

CLASS lhc_zi_hu_inbound DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS postinboundgr FOR MODIFY
      IMPORTING keys FOR ACTION InboundHu~postInboundGr RESULT result.
ENDCLASS.

CLASS lhc_zi_hu_inbound IMPLEMENTATION.
  " BAPI_INB_DELIVERY_CONFIRM_DEC does a full delivery save (posts GR, commits,
  " RAISEs RAP entity events on the inbound-delivery BO) -> illegal in a RAP
  " action. So the action only BUFFERS the delivery numbers; save() registers the
  " GR as a tRFC unit (CALL FUNCTION ... IN BACKGROUND TASK DESTINATION 'NONE',
  " legal in save). The RAP COMMIT WORK dispatches it, and the wrapper FM
  " Z_KGPL_INB_DELIVERY_GR posts + commits the GR in its own separate LUW.
  METHOD postinboundgr.
    DATA lv_delivery TYPE vbeln_vl.
    LOOP AT keys INTO DATA(ls_key).
      lv_delivery = |{ ls_key-%param-InboundDelivery ALPHA = IN }|.
      APPEND lv_delivery TO lcl_inb_buffer=>gt_deliveries.
      INSERT VALUE #( %cid = ls_key-%cid
        %param-message = |Goods receipt for inbound delivery { ls_key-%param-InboundDelivery } queued (posts on commit).| )
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
    LOOP AT lcl_inb_buffer=>gt_deliveries INTO DATA(lv_delivery).
      " tRFC unit: runs after the RAP COMMIT WORK, in its own LUW -> the delivery
      " save/commit/events happen there, isolated from this RAP behavior.
      CALL FUNCTION 'Z_KGPL_INB_DELIVERY_GR'
        IN BACKGROUND TASK
        DESTINATION 'NONE'
        EXPORTING iv_delivery = lv_delivery.
    ENDLOOP.
    CLEAR lcl_inb_buffer=>gt_deliveries.
  ENDMETHOD.
ENDCLASS.
