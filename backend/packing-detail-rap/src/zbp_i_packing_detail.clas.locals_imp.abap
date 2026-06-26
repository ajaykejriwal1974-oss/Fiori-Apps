CLASS lhc_PackingItem DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS packItems FOR MODIFY
      IMPORTING keys FOR ACTION PackingItem~packItems RESULT result.
    METHODS repackItems FOR MODIFY
      IMPORTING keys FOR ACTION PackingItem~repackItems RESULT result.
ENDCLASS.

CLASS lhc_PackingItem IMPLEMENTATION.
  METHOD packItems.
    LOOP AT keys INTO DATA(key).
      DATA(ls_param) = key-%param.
      " TODO: create the HU and pack the listed items via BAPI_HU_CREATE / BAPI_HU_PACK.
      APPEND VALUE #( %cid = key-%cid
                      %param = VALUE #( message = 'TODO: wire BAPI_HU_PACK' ) ) TO result.
    ENDLOOP.
  ENDMETHOD.
  METHOD repackItems.
    LOOP AT keys INTO DATA(key).
      DATA(ls_param) = key-%param.
      " TODO: move items from the source HU to the target HU via BAPI_HU_REPACK_ITM.
      APPEND VALUE #( %cid = key-%cid
                      %param = VALUE #( message = 'TODO: wire BAPI_HU_REPACK_ITM' ) ) TO result.
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.
