CLASS lhc_HuUnpack DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS unpackItems FOR MODIFY
      IMPORTING keys FOR ACTION HuUnpack~unpackItems RESULT result.
ENDCLASS.

CLASS lhc_HuUnpack IMPLEMENTATION.
  METHOD unpackItems.
    LOOP AT keys INTO DATA(key).
      DATA(ls_param) = key-%param.
      " TODO: unpack the items from their HUs (optionally post to the target storage location).
      APPEND VALUE #( %cid = key-%cid
                      %param = VALUE #( message = 'TODO: wire BAPI_HU_UNPACK' ) ) TO result.
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.
