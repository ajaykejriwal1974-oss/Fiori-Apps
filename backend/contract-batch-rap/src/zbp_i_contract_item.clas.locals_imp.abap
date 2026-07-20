CLASS lhc_zi_contract_item DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS updatebatches FOR MODIFY
      IMPORTING keys FOR ACTION ContractItem~updateBatches RESULT result.
ENDCLASS.

CLASS lhc_zi_contract_item IMPLEMENTATION.
  METHOD updatebatches.
    DATA: lv_doc     TYPE bapivbeln-vbeln,
          ls_hdrx    TYPE bapisdh1x,
          lt_itm_in  TYPE STANDARD TABLE OF bapisditm,
          lt_itm_inx TYPE STANDARD TABLE OF bapisditmx,
          lt_return  TYPE STANDARD TABLE OF bapiret2,
          lv_posnr   TYPE posnr_va,
          lv_count   TYPE i.

    LOOP AT keys INTO DATA(ls_key).
      CLEAR: lt_itm_in, lt_itm_inx, lt_return, lv_count, ls_hdrx.
      lv_doc = |{ ls_key-%param-SalesContract ALPHA = IN }|.
      ls_hdrx-updateflag = 'U'.

      SPLIT ls_key-%param-ItemBatchList AT ';' INTO TABLE DATA(lt_pairs).
      LOOP AT lt_pairs INTO DATA(lv_pair).
        CONDENSE lv_pair.
        CHECK lv_pair IS NOT INITIAL.
        SPLIT lv_pair AT '=' INTO DATA(lv_item) DATA(lv_batch).
        lv_posnr = lv_item.
        APPEND VALUE #( itm_number = lv_posnr batch = lv_batch ) TO lt_itm_in.
        APPEND VALUE #( itm_number = lv_posnr updateflag = 'U' batch = 'X' ) TO lt_itm_inx.
        lv_count = lv_count + 1.
      ENDLOOP.

      IF lt_itm_in IS INITIAL.
        INSERT VALUE #( %cid = ls_key-%cid %param-message = |No item/batch pairs.| ) INTO TABLE result.
        CONTINUE.
      ENDIF.

      CALL FUNCTION 'BAPI_SD_SALESDOCUMENT_CHANGE'
        EXPORTING salesdocument    = lv_doc
                  order_header_inx = ls_hdrx
        TABLES    return           = lt_return
                  order_item_in    = lt_itm_in
                  order_item_inx   = lt_itm_inx.

      READ TABLE lt_return INTO DATA(ls_err) WITH KEY type = 'E'.
      IF sy-subrc = 0.
        INSERT VALUE #( %cid = ls_key-%cid %param-message = ls_err-message ) INTO TABLE result.
      ELSE.
        INSERT VALUE #( %cid = ls_key-%cid
          %param-itemsupdated = lv_count
          %param-message = |{ lv_count } contract item(s) updated on { ls_key-%param-SalesContract }.| )
          INTO TABLE result.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.

CLASS lsc_zi_contract_item DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PROTECTED SECTION.
    METHODS save REDEFINITION.
ENDCLASS.

CLASS lsc_zi_contract_item IMPLEMENTATION.
  METHOD save.
  ENDMETHOD.
ENDCLASS.
