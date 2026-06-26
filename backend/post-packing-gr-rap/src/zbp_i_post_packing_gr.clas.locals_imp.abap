CLASS lhc_PostPackGr DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS postPackingAndGr FOR MODIFY
      IMPORTING keys FOR ACTION PostPackGr~postPackingAndGr RESULT result.
ENDCLASS.

CLASS lhc_PostPackGr IMPLEMENTATION.
  METHOD postPackingAndGr.
    LOOP AT keys INTO DATA(key).
      DATA(h)        = key-%param.
      DATA(lt_hu)    = key-%param-_item.

      IF lt_hu IS INITIAL.
        APPEND VALUE #( %cid = key-%cid %param-message = 'No handling units to post' ) TO result.
        CONTINUE.
      ENDIF.

      " Read the contents of the selected HUs from the standard HU tables
      " (VEKP header / VEPO items) and post one goods receipt for them all.
      DATA(lt_exidv) = VALUE rseloption( FOR hu IN lt_hu ( sign = 'I' option = 'EQ' low = hu-handlingunit ) ).
      SELECT i~matnr, i~charg, i~vemng, i~vemeh
        FROM vepo AS i
        INNER JOIN vekp AS k ON k~venum = i~venum
        WHERE k~exidv IN @lt_exidv
        INTO TABLE @DATA(lt_cont).

      IF lt_cont IS INITIAL.
        APPEND VALUE #( %cid = key-%cid %param-message = 'Selected HUs have no items' ) TO result.
        CONTINUE.
      ENDIF.

      DATA(lv_today) = cl_abap_context_info=>get_system_date( ).
      DATA(ls_gm_header) = VALUE bapi2017_gm_head_01(
                             pstng_date = lv_today doc_date = lv_today pr_uname = sy-uname ).
      " GM_CODE '01' = goods receipt. VERIFY against the GR scenario / movement type.
      DATA(ls_gm_code) = VALUE bapi2017_gm_code( gm_code = '01' ).

      DATA lt_gm_item TYPE STANDARD TABLE OF bapi2017_gm_item_create.
      lt_gm_item = VALUE #( FOR c IN lt_cont (
                     material  = c-matnr
                     plant     = h-plant
                     stge_loc  = h-storagelocation
                     batch     = c-charg
                     move_type = h-movementtype
                     entry_qnt = c-vemng
                     entry_uom = c-vemeh ) ).

      DATA: lv_matdoc  TYPE bapi2017_gm_head_ret-mat_doc,
            lv_matyear TYPE bapi2017_gm_head_ret-doc_year.
      DATA lt_return TYPE STANDARD TABLE OF bapiret2.

      CALL FUNCTION 'BAPI_GOODSMVT_CREATE'
        EXPORTING goodsmvt_header  = ls_gm_header
                  goodsmvt_code    = ls_gm_code
        IMPORTING materialdocument = lv_matdoc
                  matdocumentyear  = lv_matyear
        TABLES    goodsmvt_item    = lt_gm_item
                  return           = lt_return.

      DATA(lv_err) = REDUCE string( INIT s = ``
                       FOR r IN lt_return WHERE ( type = 'E' OR type = 'A' )
                       NEXT s = s && r-message && ` ` ).
      IF lv_err IS NOT INITIAL.
        CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.
        APPEND VALUE #( %cid = key-%cid %param = VALUE #( message = lv_err ) ) TO result.
      ELSE.
        CALL FUNCTION 'BAPI_TRANSACTION_COMMIT' EXPORTING wait = abap_true.
        APPEND VALUE #( %cid = key-%cid
                        %param = VALUE #( materialdocument = lv_matdoc
                                          message = |GR posted: material document { lv_matdoc }| ) ) TO result.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.
