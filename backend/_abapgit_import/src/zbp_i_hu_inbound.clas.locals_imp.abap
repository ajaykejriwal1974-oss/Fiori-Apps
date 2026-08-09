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
      CALL FUNCTION 'Z_KGPL_INB_DELIVERY_GR'
        IN BACKGROUND TASK
        DESTINATION 'NONE'
        EXPORTING iv_delivery = lv_delivery.
    ENDLOOP.
    CLEAR lcl_inb_buffer=>gt_deliveries.
  ENDMETHOD.
ENDCLASS.
