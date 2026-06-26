CLASS lhc_PostPackGr DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS postPackingAndGr FOR MODIFY
      IMPORTING keys FOR ACTION PostPackGr~postPackingAndGr RESULT result.
ENDCLASS.

CLASS lhc_PostPackGr IMPLEMENTATION.
  METHOD postPackingAndGr.
    LOOP AT keys INTO DATA(key).
      DATA(ls_param) = key-%param.
      " TODO: pack the HUs (BAPI_HU_PACK) and post the goods receipt (BAPI_GOODSMVT_CREATE) in one transaction.
      APPEND VALUE #( %cid = key-%cid
                      %param = VALUE #( message = 'TODO: wire BAPI_GOODSMVT_CREATE' ) ) TO result.
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.
