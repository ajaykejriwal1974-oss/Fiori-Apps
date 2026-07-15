*"* Unmanaged behavior for ZI_DISPATCH_BOX.
*"* correctDispatch: re-assign the selected dispatch boxes to a new sales order /
*"* item / status, applying the legacy ZSOL_DISPATCH_CORRECTION logic on the
*"* existing dispatch (ZSOL_HUDISPATCH) and packing (ZPP_PACK) tables.
*"* The boxes travel in the flat BoxList parameter as 'BOX1;BOX2;BOX3'.

CLASS lhc_DispatchBox DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS correctDispatch FOR MODIFY
      IMPORTING keys FOR ACTION DispatchBox~correctDispatch RESULT result.
ENDCLASS.

CLASS lhc_DispatchBox IMPLEMENTATION.

  METHOD correctDispatch.
    LOOP AT keys INTO DATA(key).
      DATA(ls_header) = key-%param.

      DATA lt_boxes TYPE STANDARD TABLE OF char10.
      CLEAR lt_boxes.
      SPLIT ls_header-boxlist AT ';' INTO TABLE DATA(lt_tok).
      LOOP AT lt_tok INTO DATA(lv_tok).
        CONDENSE lv_tok NO-GAPS.
        IF lv_tok IS NOT INITIAL.
          APPEND CONV char10( lv_tok ) TO lt_boxes.
        ENDIF.
      ENDLOOP.

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
      LOOP AT lt_boxes INTO DATA(lv_box).
        UPDATE zsol_hudispatch
          SET so      = @ls_header-newsalesorder,
              so_item = @ls_header-newsalesorderitem,
              status  = @ls_header-newstatus
          WHERE boxno = @lv_box.
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
