*"* Unmanaged behavior for ZI_HU_UNPACK.
*"* unpackItems: unpack the given HU items. The items travel in the flat
*"* HuItemList parameter as 'HU=ITEM;HU=ITEM' (e.g. 'HU1=0001;HU1=0002') -
*"* material/batch/quantity are read from VEPO on the server.

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
      DATA(h) = key-%param.

      DATA(lv_count) = 0.
      DATA lt_return TYPE STANDARD TABLE OF bapiret2.
      SPLIT h-huitemlist AT ';' INTO TABLE DATA(lt_tok).
      LOOP AT lt_tok INTO DATA(lv_tok).
        CONDENSE lv_tok NO-GAPS.
        IF lv_tok IS INITIAL. CONTINUE. ENDIF.
        SPLIT lv_tok AT '=' INTO DATA(lv_hu) DATA(lv_item).

        " read the item detail from the standard HU tables
        SELECT SINGLE i~matnr, i~charg, i~vemng, i~vemeh
          FROM vepo AS i
          INNER JOIN vekp AS k ON k~venum = i~venum
          WHERE k~exidv = @lv_hu AND i~venpo = @lv_item
          INTO @DATA(ls_cont).
        IF sy-subrc <> 0. CONTINUE. ENDIF.

        CALL FUNCTION 'BAPI_HU_UNPACK'
          EXPORTING hukey      = lv_hu
                    materialnr = ls_cont-matnr
                    batch      = ls_cont-charg
                    pack_qty   = ls_cont-vemng
                    unit       = ls_cont-vemeh
                    dest_stloc = h-targetstoragelocation
          TABLES    return     = lt_return.
        lv_count += 1.
      ENDLOOP.

      IF lv_count = 0.
        APPEND VALUE #( %cid = key-%cid %param-message = 'No items to unpack' ) TO result.
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
                        %param = VALUE #( message = |Unpacked { lv_count } item(s) to { h-targetstoragelocation }| ) ) TO result.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.
