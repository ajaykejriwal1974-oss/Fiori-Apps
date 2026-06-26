CLASS lhc_MtoStock DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS convertToMts FOR MODIFY
      IMPORTING keys FOR ACTION MtoStock~convertToMts RESULT result.
ENDCLASS.

CLASS lhc_MtoStock IMPLEMENTATION.
  METHOD convertToMts.
    LOOP AT keys INTO DATA(key).
      DATA(ls_param) = key-%param.
      " TODO: post the special-stock conversion (sales-order stock -> own stock, e.g. movement type 411 E) via BAPI_GOODSMVT_CREATE.
      APPEND VALUE #( %cid = key-%cid
                      %param = VALUE #( message = 'TODO: wire BAPI_GOODSMVT_CREATE' ) ) TO result.
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.
