CLASS lhc_HuUnpack DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS unpackItems FOR MODIFY
      IMPORTING keys FOR ACTION HuUnpack~unpackItems RESULT result.
ENDCLASS.

CLASS lhc_HuUnpack IMPLEMENTATION.
  METHOD unpackItems.
    " VERIFY: BAPI_HU_UNPACK parameter names vary by release; the target storage
    " location move may be a separate goods movement (BAPI_GOODSMVT_CREATE).
    LOOP AT keys INTO DATA(key).
      DATA(h)        = key-%param.
      DATA(lt_items) = key-%param-_item.
      IF lt_items IS INITIAL.
        APPEND VALUE #( %cid = key-%cid %param-message = 'No items to unpack' ) TO result.
        CONTINUE.
      ENDIF.
      DATA lt_return TYPE STANDARD TABLE OF bapiret2.
      LOOP AT lt_items INTO DATA(it).
        CALL FUNCTION 'BAPI_HU_UNPACK'
          EXPORTING hukey      = it-handlingunit
                    materialnr = it-material
                    batch      = it-batch
                    pack_qty   = it-quantity
                    unit       = it-unit
                    dest_stloc = h-targetstoragelocation
          TABLES    return     = lt_return.
      ENDLOOP.
      DATA(lv_err) = REDUCE string( INIT s = ``
                       FOR r IN lt_return WHERE ( type = 'E' OR type = 'A' )
                       NEXT s = s && r-message && ` ` ).
      IF lv_err IS NOT INITIAL.
        CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.
        APPEND VALUE #( %cid = key-%cid %param = VALUE #( message = lv_err ) ) TO result.
      ELSE.
        CALL FUNCTION 'BAPI_TRANSACTION_COMMIT' EXPORTING wait = abap_true.
        APPEND VALUE #( %cid = key-%cid
                        %param = VALUE #( message = |Unpacked { lines( lt_items ) } item(s) to { h-targetstoragelocation }| ) ) TO result.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.
