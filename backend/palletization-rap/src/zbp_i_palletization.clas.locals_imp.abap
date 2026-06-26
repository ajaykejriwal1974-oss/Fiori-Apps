CLASS lhc_Pallet DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS packPallet FOR MODIFY
      IMPORTING keys FOR ACTION Pallet~packPallet RESULT result.
ENDCLASS.

CLASS lhc_Pallet IMPLEMENTATION.
  METHOD packPallet.
    LOOP AT keys INTO DATA(key).
      DATA(ls_param) = key-%param.
      " TODO: create the pallet HU and pack the listed box HUs onto it via BAPI_HU_CREATE / BAPI_HU_PACK.
      APPEND VALUE #( %cid = key-%cid
                      %param = VALUE #( message = 'TODO: wire BAPI_HU_PACK' ) ) TO result.
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.
