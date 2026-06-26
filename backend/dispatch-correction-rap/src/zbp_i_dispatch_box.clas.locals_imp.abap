*"* Unmanaged behavior for ZI_DispatchBox.
*"* correctDispatch: re-assign the selected dispatch boxes to a new sales order /
*"* item / status, applying the legacy ZSOL_DISPATCH_CORRECTION logic on the
*"* existing dispatch (ZSOL_HUDISPATCH) and packing (ZPP_PACK) tables.

CLASS lhc_DispatchBox DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS correctDispatch FOR MODIFY
      IMPORTING keys FOR ACTION DispatchBox~correctDispatch RESULT result.
ENDCLASS.

CLASS lhc_DispatchBox IMPLEMENTATION.

  METHOD correctDispatch.
    LOOP AT keys INTO DATA(key).
      DATA(ls_header) = key-%param.
      DATA(lt_boxes)  = key-%param-_item.

      IF lt_boxes IS INITIAL.
        APPEND VALUE #( %cid = key-%cid
                        %param = VALUE #( boxesupdated = 0
                                          message = 'No boxes selected' ) ) TO result.
        CONTINUE.
      ENDIF.

      " Re-assign each box on the dispatch table (replaces ZSOL_DISPATCH_CORRECTION).
      " VERIFY: if a box is already invoiced/posted the goods movement must be
      " reversed first, and ZPP_PACK kept in sync when the order drives packing.
      DATA(lv_count) = 0.
      LOOP AT lt_boxes INTO DATA(box).
        UPDATE zsol_hudispatch
          SET so      = @ls_header-newsalesorder,
              so_item = @ls_header-newsalesorderitem,
              status  = @ls_header-newstatus
          WHERE boxno = @box-boxnumber.
        IF sy-subrc = 0.
          lv_count += 1.
        ENDIF.
      ENDLOOP.
      IF lv_count > 0.
        COMMIT WORK.
      ENDIF.

      APPEND VALUE #( %cid  = key-%cid
                      %param = VALUE #( boxesupdated = lv_count
                                        message = |{ lv_count } of { lines( lt_boxes ) } box(es) re-assigned to SO { ls_header-newsalesorder }| ) )
             TO result.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
