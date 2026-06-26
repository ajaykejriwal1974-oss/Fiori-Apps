CLASS lhc_PackingItem DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS packItems FOR MODIFY
      IMPORTING keys FOR ACTION PackingItem~packItems RESULT result.
    METHODS repackItems FOR MODIFY
      IMPORTING keys FOR ACTION PackingItem~repackItems RESULT result.
ENDCLASS.

CLASS lhc_PackingItem IMPLEMENTATION.
  METHOD packItems.
    " VERIFY: the HU BAPI interface (BAPI_HU_CREATE / BAPI_HU_PACK) parameter and
    " structure names vary by release - confirm in SE37 / ADT before activating.
    LOOP AT keys INTO DATA(key).
      DATA(h)        = key-%param.
      DATA(lt_items) = key-%param-_item.
      IF lt_items IS INITIAL.
        APPEND VALUE #( %cid = key-%cid %param-message = 'No items to pack' ) TO result.
        CONTINUE.
      ENDIF.
      DATA lt_return TYPE STANDARD TABLE OF bapiret2.

      " 1) create the HU from the packaging material
      DATA lv_huexid TYPE exidv.
      CALL FUNCTION 'BAPI_HU_CREATE'
        EXPORTING hukey_ref     = h-reference
                  packing_matnr = h-packagingmaterial
        IMPORTING huexid        = lv_huexid
        TABLES    return        = lt_return.

      " 2) pack each material item into the new HU
      LOOP AT lt_items INTO DATA(it).
        CALL FUNCTION 'BAPI_HU_PACK'
          EXPORTING hukey      = lv_huexid
                    materialnr = it-material
                    batch      = it-batch
                    pack_qty   = it-quantity
                    unit       = it-unit
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
                        %param = VALUE #( handlingunit = lv_huexid
                                          message = |HU { lv_huexid } packed with { lines( lt_items ) } item(s)| ) ) TO result.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.
  METHOD repackItems.
    " VERIFY BAPI_HU_REPACK_ITM interface for your release.
    LOOP AT keys INTO DATA(key).
      DATA(h)        = key-%param.
      DATA(lt_items) = key-%param-_item.
      DATA lt_return TYPE STANDARD TABLE OF bapiret2.
      LOOP AT lt_items INTO DATA(it).
        CALL FUNCTION 'BAPI_HU_REPACK_ITM'
          EXPORTING source_hu = h-sourcehandlingunit
                    dest_hu   = h-targethandlingunit
                    hu_item   = it-handlingunititem
                    pack_qty  = it-quantity
          TABLES    return    = lt_return.
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
                        %param = VALUE #( message = |Repacked { lines( lt_items ) } item(s) { h-sourcehandlingunit } -> { h-targethandlingunit }| ) ) TO result.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.
