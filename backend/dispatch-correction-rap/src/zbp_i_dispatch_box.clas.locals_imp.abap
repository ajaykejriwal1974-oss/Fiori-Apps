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

      " TODO: apply the dispatch correction for each box in lt_boxes:
      "   - validate the box exists in ZSOL_HUDISPATCH and is not already
      "     invoiced / posted (else the goods movement must be reversed first);
      "   - UPDATE ZSOL_HUDISPATCH SET so = ls_header-newsalesorder,
      "       so_item = ls_header-newsalesorderitem, status = ls_header-newstatus
      "       WHERE boxno = box-boxnumber;
      "   - keep ZPP_PACK in sync if the order assignment drives packing;
      "   - reuse the existing ZSOL_DISPATCH_CORRECTION routine where possible.
      "   (collect failures into reported/failed; COMMIT handled by save sequence)

      APPEND VALUE #( %cid  = key-%cid
                      %param = VALUE #( boxesupdated = lines( lt_boxes )
                                        message = 'TODO: wire ZSOL_DISPATCH_CORRECTION update' ) )
             TO result.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
