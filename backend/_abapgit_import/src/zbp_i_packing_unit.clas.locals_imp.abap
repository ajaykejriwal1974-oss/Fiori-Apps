*"* Unmanaged behavior for ZI_PACKING_UNIT.
*"* createHandlingUnits: build the cone -> carton -> pallet HU hierarchy for the
*"* reference and pack it via the standard HU API. The levels travel bottom-up
*"* in the flat UnitList parameter as 'PACKMAT=QTY;PACKMAT=QTY'.

CLASS lhc_PackingUnit DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS createHandlingUnits FOR MODIFY
      IMPORTING keys FOR ACTION PackingUnit~createHandlingUnits RESULT result.
ENDCLASS.

CLASS lhc_PackingUnit IMPLEMENTATION.

  METHOD createHandlingUnits.
    LOOP AT keys INTO DATA(key).
      DATA(ls_header) = key-%param.

      " Build the Cone -> Carton -> Pallet HU hierarchy. VERIFY the BAPI_HU_CREATE /
      " BAPI_HU_PACK parameter names against your release.
      DATA lt_return TYPE STANDARD TABLE OF bapiret2.
      DATA: lv_prev_hu TYPE exidv,
            lv_top_hu  TYPE exidv,
            lv_count   TYPE i.
      CLEAR: lv_prev_hu, lv_top_hu, lv_count.

      SPLIT ls_header-unitlist AT ';' INTO TABLE DATA(lt_tok).
      LOOP AT lt_tok INTO DATA(lv_tok).
        CONDENSE lv_tok NO-GAPS.
        IF lv_tok IS INITIAL. CONTINUE. ENDIF.
        SPLIT lv_tok AT '=' INTO DATA(lv_packmat) DATA(lv_qty_c).
        DATA lv_qty TYPE vemng.
        lv_qty = lv_qty_c.

        DATA lv_hu TYPE exidv.
        CALL FUNCTION 'BAPI_HU_CREATE'
          EXPORTING hukey_ref     = ls_header-reference
                    packing_matnr = lv_packmat
          IMPORTING huexid        = lv_hu
          TABLES    return        = lt_return.
        IF lv_prev_hu IS INITIAL.
          " lowest level (Cone): pack the material content
          CALL FUNCTION 'BAPI_HU_PACK'
            EXPORTING hukey      = lv_hu
                      materialnr = ls_header-material
                      batch      = ls_header-batch
                      pack_qty   = lv_qty
            TABLES    return     = lt_return.
        ELSE.
          " pack the lower-level HU into this one
          CALL FUNCTION 'BAPI_HU_PACK'
            EXPORTING hukey    = lv_hu
                      lower_hu = lv_prev_hu
            TABLES    return   = lt_return.
        ENDIF.
        lv_prev_hu = lv_hu.
        lv_top_hu  = lv_hu.
        lv_count  += 1.
      ENDLOOP.

      IF lv_count = 0.
        APPEND VALUE #( %cid = key-%cid
                        %param-message = 'No packing units provided' ) TO result.
        CONTINUE.
      ENDIF.

      DATA(lv_err) = REDUCE string( INIT s = ``
                       FOR r IN lt_return WHERE ( type = 'E' OR type = 'A' )
                       NEXT s = s && r-message && ` ` ).
      IF lv_err IS NOT INITIAL.
        CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.
        APPEND VALUE #( %cid = key-%cid %param = VALUE #( message = lv_err ) ) TO result.
      ELSE.
        CALL FUNCTION 'BAPI_TRANSACTION_COMMIT' EXPORTING wait = abap_true.
        APPEND VALUE #( %cid = key-%cid
                        %param = VALUE #( handlingunitscreated = lv_count
                                          tophandlingunit      = lv_top_hu
                                          message              = |Created { lv_count } HU level(s); top HU { lv_top_hu }| ) ) TO result.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
