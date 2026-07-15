*"* Unmanaged behavior for ZI_PALLETIZATION.
*"* packPallet: create the pallet HU and pack the box HUs onto it. The boxes
*"* travel in the flat BoxHuList parameter as 'HU1;HU2;HU3'.

CLASS lhc_Pallet DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS packPallet FOR MODIFY
      IMPORTING keys FOR ACTION Pallet~packPallet RESULT result.
ENDCLASS.

CLASS lhc_Pallet IMPLEMENTATION.
  METHOD packPallet.
    " VERIFY: BAPI_HU_CREATE / BAPI_HU_PACK parameter names vary by release.
    LOOP AT keys INTO DATA(key).
      DATA(h) = key-%param.

      DATA lt_boxes TYPE STANDARD TABLE OF exidv.
      CLEAR lt_boxes.
      SPLIT h-boxhulist AT ';' INTO TABLE DATA(lt_tok).
      LOOP AT lt_tok INTO DATA(lv_tok).
        CONDENSE lv_tok NO-GAPS.
        IF lv_tok IS NOT INITIAL.
          APPEND CONV exidv( lv_tok ) TO lt_boxes.
        ENDIF.
      ENDLOOP.

      IF lt_boxes IS INITIAL.
        APPEND VALUE #( %cid = key-%cid %param-message = 'No boxes to palletize' ) TO result.
        CONTINUE.
      ENDIF.
      DATA lt_return TYPE STANDARD TABLE OF bapiret2.

      " 1) create the pallet HU
      DATA lv_pallet TYPE exidv.
      CALL FUNCTION 'BAPI_HU_CREATE'
        EXPORTING hukey_ref     = h-reference
                  packing_matnr = h-palletpackagingmaterial
        IMPORTING huexid        = lv_pallet
        TABLES    return        = lt_return.

      " 2) pack each box HU onto the pallet as a lower-level HU
      LOOP AT lt_boxes INTO DATA(lv_box).
        CALL FUNCTION 'BAPI_HU_PACK'
          EXPORTING hukey    = lv_pallet
                    lower_hu = lv_box
          TABLES    return   = lt_return.
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
                        %param = VALUE #( pallet = lv_pallet
                                          boxespacked = lines( lt_boxes )
                                          message = |Pallet { lv_pallet } packed with { lines( lt_boxes ) } box(es)| ) ) TO result.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.
