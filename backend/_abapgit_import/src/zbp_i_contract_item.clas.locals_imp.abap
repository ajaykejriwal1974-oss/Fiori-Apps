CLASS lcl_ctr_buffer DEFINITION.
  PUBLIC SECTION.
    TYPES: BEGIN OF ty_item,
             doc   TYPE vbeln_va,
             posnr TYPE posnr_va,
             batch TYPE charg_d,
           END OF ty_item.
    CLASS-DATA gt_items TYPE STANDARD TABLE OF ty_item WITH EMPTY KEY.
ENDCLASS.

CLASS lhc_zi_contract_item DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS updatebatches FOR MODIFY
      IMPORTING keys FOR ACTION ContractItem~updateBatches RESULT result.
ENDCLASS.

CLASS lhc_zi_contract_item IMPLEMENTATION.
  METHOD updatebatches.
    DATA: lv_doc   TYPE vbeln_va,
          lv_posnr TYPE posnr_va,
          lv_count TYPE i.
    LOOP AT keys INTO DATA(ls_key).
      lv_doc   = |{ ls_key-%param-SalesContract ALPHA = IN }|.
      lv_count = 0.
      SPLIT ls_key-%param-ItemBatchList AT ';' INTO TABLE DATA(lt_pairs).
      LOOP AT lt_pairs INTO DATA(lv_pair).
        CONDENSE lv_pair.
        CHECK lv_pair IS NOT INITIAL.
        SPLIT lv_pair AT '=' INTO DATA(lv_item) DATA(lv_batch).
        lv_posnr = lv_item.
        APPEND VALUE #( doc = lv_doc posnr = lv_posnr batch = lv_batch ) TO lcl_ctr_buffer=>gt_items.
        lv_count = lv_count + 1.
      ENDLOOP.
      INSERT VALUE #( %cid = ls_key-%cid
        %param-itemsupdated = lv_count
        %param-message = |{ lv_count } contract item(s) queued for batch update on { ls_key-%param-SalesContract }.| )
        INTO TABLE result.
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.

CLASS lsc_zi_contract_item DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PROTECTED SECTION.
    METHODS save REDEFINITION.
ENDCLASS.

CLASS lsc_zi_contract_item IMPLEMENTATION.
  METHOD save.
    DATA: ls_hdr     TYPE bapisdh1,
          ls_hdrx    TYPE bapisdh1x,
          lt_itm_in  TYPE STANDARD TABLE OF bapisditm,
          lt_itm_inx TYPE STANDARD TABLE OF bapisditmx,
          lt_return  TYPE STANDARD TABLE OF bapiret2.

    LOOP AT lcl_ctr_buffer=>gt_items INTO DATA(ls_row)
         GROUP BY ( doc = ls_row-doc ) INTO DATA(lo_group).
      CLEAR: lt_itm_in, lt_itm_inx, lt_return, ls_hdrx.
      ls_hdrx-updateflag = 'U'.
      LOOP AT GROUP lo_group INTO DATA(ls_it).
        APPEND VALUE #( itm_number = ls_it-posnr batch = ls_it-batch ) TO lt_itm_in.
        APPEND VALUE #( itm_number = ls_it-posnr updateflag = 'U' batch = 'X' ) TO lt_itm_inx.
      ENDLOOP.
      CALL FUNCTION 'BAPI_CUSTOMERCONTRACT_CHANGE'
        EXPORTING salesdocument       = CONV bapivbeln-vbeln( lo_group-doc )
                  contract_header_in  = ls_hdr
                  contract_header_inx = ls_hdrx
        TABLES    return              = lt_return
                  contract_item_in    = lt_itm_in
                  contract_item_inx   = lt_itm_inx.
    ENDLOOP.
    CLEAR lcl_ctr_buffer=>gt_items.
  ENDMETHOD.
ENDCLASS.
