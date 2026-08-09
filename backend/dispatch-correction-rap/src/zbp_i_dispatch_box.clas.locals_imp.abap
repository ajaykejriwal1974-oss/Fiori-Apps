CLASS lhc_zi_dispatch_box DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS correctdispatch FOR MODIFY
      IMPORTING keys FOR ACTION DispatchBox~correctDispatch RESULT result.
ENDCLASS.

CLASS lhc_zi_dispatch_box IMPLEMENTATION.
  METHOD correctdispatch.
    DATA lv_boxno TYPE zsol_hudispatch-boxno.
    LOOP AT keys INTO DATA(ls_key).
      DATA(lv_count) = 0.
      DATA(lv_so)   = ls_key-%param-NewSalesOrder.
      DATA(lv_soi)  = ls_key-%param-NewSalesOrderItem.
      DATA(lv_stat) = ls_key-%param-NewStatus.
      SPLIT ls_key-%param-BoxList AT ';' INTO TABLE DATA(lt_boxes).
      LOOP AT lt_boxes INTO DATA(lv_box).
        CONDENSE lv_box.
        CHECK lv_box IS NOT INITIAL.
        lv_boxno = lv_box.
        UPDATE zsol_hudispatch
           SET so = @lv_so, so_item = @lv_soi, status = @lv_stat
         WHERE boxno = @lv_boxno.
        lv_count += sy-dbcnt.
      ENDLOOP.
      INSERT VALUE #( %cid = ls_key-%cid
        %param-boxesupdated = lv_count
        %param-message = |{ lv_count } box(es) reassigned to SO { lv_so }/{ lv_soi }, status { lv_stat }.| )
        INTO TABLE result.
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.

CLASS lsc_zi_dispatch_box DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PROTECTED SECTION.
    METHODS save REDEFINITION.
ENDCLASS.

CLASS lsc_zi_dispatch_box IMPLEMENTATION.
  METHOD save.
  ENDMETHOD.
ENDCLASS.
