CLASS lhc_HuPhysInv DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS createPhysInvDoc FOR MODIFY
      IMPORTING keys FOR ACTION HuPhysInv~createPhysInvDoc RESULT result.
ENDCLASS.

CLASS lhc_HuPhysInv IMPLEMENTATION.
  METHOD createPhysInvDoc.
    LOOP AT keys INTO DATA(key).
      DATA(ls_param) = key-%param.
      " TODO: create the physical-inventory document for the HU stock via BAPI_MATPHYSINV_CREATE_MULT.
      APPEND VALUE #( %cid = key-%cid
                      %param = VALUE #( message = 'TODO: wire BAPI_MATPHYSINV_CREATE_MULT' ) ) TO result.
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.
