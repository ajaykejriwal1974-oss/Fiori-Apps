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

      " TODO: map ls_header + lt_items to BAPI_GOODSMVT_CREATE and post.
      "   gm_header  = VALUE #( pstng_date = cl_abap_context_info=>get_system_date( ) ... )
      "   gm_code    = '03'                       " e.g. MB1B/transfer - per movement type
      "   gm_items   = VALUE #( FOR it IN lt_items (
      "                  material   = it-material
      "                  plant      = ls_header-plant
      "                  stge_loc   = ls_header-storagelocation
      "                  move_stloc = ls_header-receivingstoragelocation
      "                  batch      = it-batch
      "                  move_type  = ls_header-movementtype
      "                  entry_qnt  = it-quantity
      "                  entry_uom  = it-unit ) )
      "   CALL FUNCTION 'BAPI_GOODSMVT_CREATE' ... IMPORTING materialdocument = lv_matdoc ...
      "   (collect BAPI return into reported/failed; commit on success)

      APPEND VALUE #( %cid  = key-%cid
                      %param = VALUE #( materialdocument     = '' " lv_matdoc
                                        materialdocumentyear = ''
                                        message              = 'TODO: wire BAPI_GOODSMVT_CREATE' ) )
             TO result.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
