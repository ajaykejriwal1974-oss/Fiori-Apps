*"* Unmanaged behavior for ZI_HU_Item.
*"* postGoodsMovement: build one BAPI_GOODSMVT_CREATE call from the header +
*"* scanned items and return the material document number.

CLASS lhc_HuItem DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS postGoodsMovement FOR MODIFY
      IMPORTING keys FOR ACTION HuItem~postGoodsMovement RESULT result.
ENDCLASS.

CLASS lhc_HuItem IMPLEMENTATION.

  METHOD postGoodsMovement.
    LOOP AT keys INTO DATA(key).
      DATA(ls_header) = key-%param.
      DATA(lt_items)  = key-%param-_item.

      IF lt_items IS INITIAL.
        APPEND VALUE #( %cid = key-%cid
                        %param-message = 'No items to post' ) TO result.
        CONTINUE.
      ENDIF.

      DATA(lv_today) = cl_abap_context_info=>get_system_date( ).
      DATA(ls_gm_header) = VALUE bapi2017_gm_head_01(
                             pstng_date = lv_today
                             doc_date   = lv_today
                             pr_uname   = sy-uname ).

      " GM_CODE selects the transaction. '04' = transfer posting (MB1B); use '03'
      " for a goods issue (MB1A) or '01' for a receipt - VERIFY against the
      " movement type the box/HU flow uses.
      DATA(ls_gm_code) = VALUE bapi2017_gm_code( gm_code = '04' ).

      DATA lt_gm_item TYPE STANDARD TABLE OF bapi2017_gm_item_create.
      lt_gm_item = VALUE #( FOR it IN lt_items (
                     material   = it-material
                     plant      = ls_header-plant
                     stge_loc   = ls_header-storagelocation
                     move_stloc = ls_header-receivingstoragelocation
                     batch      = it-batch
                     move_type  = ls_header-movementtype
                     entry_qnt  = it-quantity
                     entry_uom  = it-unit ) ).

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

      DATA(lv_errors) = REDUCE string( INIT s = ``
                          FOR ls_ret IN lt_return WHERE ( type = 'E' OR type = 'A' )
                          NEXT s = s && ls_ret-message && ` ` ).

      IF lv_errors IS NOT INITIAL.
        CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.
        APPEND VALUE #( %cid  = key-%cid
                        %param = VALUE #( message = lv_errors ) ) TO result.
      ELSE.
        " Posting from the action is acceptable here - the service has no managed
        " persistence; for strict RAP, move the BAPI to the saver (save_modified).
        CALL FUNCTION 'BAPI_TRANSACTION_COMMIT' EXPORTING wait = abap_true.
        APPEND VALUE #( %cid  = key-%cid
                        %param = VALUE #( materialdocument     = lv_matdoc
                                          materialdocumentyear = lv_matyear
                                          message = |Material document { lv_matdoc } posted| ) ) TO result.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
