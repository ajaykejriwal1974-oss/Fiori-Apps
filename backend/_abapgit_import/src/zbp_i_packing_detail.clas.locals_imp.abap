*"* Unmanaged behavior for ZI_PACKING_DETAIL.
*"* packItems:   create an HU and pack material items into it. Items travel in
*"*              the flat ItemList parameter as 'MATERIAL=BATCH=QTY=UNIT;...'
*"*              (decimal point in QTY, e.g. 'MAT1=B001=10.500=KG').
*"* repackItems: move HU items between HUs. Items travel in the flat ItemList
*"*              parameter as 'HUITEM=QTY;HUITEM=QTY'.

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
      DATA(h) = key-%param.
      DATA lt_return TYPE STANDARD TABLE OF bapiret2.

      " 1) create the HU from the packaging material
      DATA lv_huexid TYPE exidv.
      CALL FUNCTION 'BAPI_HU_CREATE'
        EXPORTING hukey_ref     = h-reference
                  packing_matnr = h-packagingmaterial
        IMPORTING huexid        = lv_huexid
        TABLES    return        = lt_return.

      " 2) pack each material item into the new HU
      DATA(lv_count) = 0.
      SPLIT h-itemlist AT ';' INTO TABLE DATA(lt_tok).
      LOOP AT lt_tok INTO DATA(lv_tok).
        CONDENSE lv_tok NO-GAPS.
        IF lv_tok IS INITIAL. CONTINUE. ENDIF.
        SPLIT lv_tok AT '=' INTO DATA(lv_mat) DATA(lv_batch) DATA(lv_qty_c) DATA(lv_unit).
        DATA lv_qty TYPE vemng.
        lv_qty = lv_qty_c.
        CALL FUNCTION 'BAPI_HU_PACK'
          EXPORTING hukey      = lv_huexid
                    materialnr = lv_mat
                    batch      = lv_batch
                    pack_qty   = lv_qty
                    unit       = lv_unit
          TABLES    return     = lt_return.
        lv_count += 1.
      ENDLOOP.

      IF lv_count = 0.
        APPEND VALUE #( %cid = key-%cid %param-message = 'No items to pack' ) TO result.
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
                        %param = VALUE #( handlingunit = lv_huexid
                                          message = |HU { lv_huexid } packed with { lv_count } item(s)| ) ) TO result.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.
  METHOD repackItems.
    " VERIFY BAPI_HU_REPACK_ITM interface for your release.
    LOOP AT keys INTO DATA(key).
      DATA(h) = key-%param.
      DATA lt_return TYPE STANDARD TABLE OF bapiret2.
      DATA(lv_count) = 0.
      SPLIT h-itemlist AT ';' INTO TABLE DATA(lt_tok).
      LOOP AT lt_tok INTO DATA(lv_tok).
        CONDENSE lv_tok NO-GAPS.
        IF lv_tok IS INITIAL. CONTINUE. ENDIF.
        SPLIT lv_tok AT '=' INTO DATA(lv_item) DATA(lv_qty_c).
        DATA lv_qty TYPE vemng.
        lv_qty = lv_qty_c.
        CALL FUNCTION 'BAPI_HU_REPACK_ITM'
          EXPORTING source_hu = h-sourcehandlingunit
                    dest_hu   = h-targethandlingunit
                    hu_item   = lv_item
                    pack_qty  = lv_qty
          TABLES    return    = lt_return.
        lv_count += 1.
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
                        %param = VALUE #( message = |Repacked { lv_count } item(s) { h-sourcehandlingunit } -> { h-targethandlingunit }| ) ) TO result.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.
