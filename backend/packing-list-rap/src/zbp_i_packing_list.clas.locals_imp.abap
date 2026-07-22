*"* Local implementation for the Packing List behavior (unmanaged).
*"* Ported from the legacy ZSD_PACKING_LIST_01 logic (class include
*"* ZINC_PACKING_CLASS_01): the packing list is the PKLST assignment on the box
*"* table ZPP_PACK — NOT a separate table.
*"*   - create/change (save_packing_list): UPDATE zpp_pack SET vbeln/posnr/pklst/pldate
*"*   - delete (delete_packing): INSERT zplistd (log) then clear the assignment
*"*
*"* >>> VERIFY before trusting on live data (this writes to ZPP_PACK): <<<
*"*  1. GJAHR: zpp_pack is keyed boxno + gjahr. The flat action carries only the
*"*     box number, so each box's year is resolved with SELECT SINGLE gjahr. If a
*"*     box number can repeat across years on your data, pass gjahr explicitly
*"*     instead (add it to ZD_PACKING_LIST_IMPORT and the read model).
*"*  2. PKLST numbering: legacy sets pklst = wa_tb1-buzei (a sequential line no.).
*"*     Here pklst = the PackListItem action parameter — confirm the caller supplies
*"*     the intended number, or generate the next number per sales order.
*"*  3. ZPLISTD fields: the legacy fills it_del from the current rows; here the key
*"*     fields (vbeln/posnr/pklst/boxno) are logged. Add audit fields if your
*"*     ZPLISTD has them and they are mandatory.
*"*  4. COMMIT: no explicit COMMIT WORK — the OData V4 action request commits the
*"*     RAP LUW on success (do NOT add COMMIT WORK inside a handler).
*"* TEST on a throwaway sales order / boxes before using against live dispatch.

CLASS lhc_packing_list DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    TYPES tt_boxes TYPE STANDARD TABLE OF zboxno WITH EMPTY KEY.

    METHODS createPackingList FOR MODIFY
      IMPORTING keys FOR ACTION PackingList~createPackingList RESULT result.

    METHODS changePackingList FOR MODIFY
      IMPORTING keys FOR ACTION PackingList~changePackingList RESULT result.

    METHODS deletePackingList FOR MODIFY
      IMPORTING keys FOR ACTION PackingList~deletePackingList RESULT result.

    METHODS split_boxes IMPORTING iv_list         TYPE string
                        RETURNING VALUE(rt_boxes) TYPE tt_boxes.

    "  Shared assign logic for create + change (both = save_packing_list).
    METHODS assign_boxes IMPORTING iv_sales_order      TYPE zpp_pack-vbeln
                                   iv_sales_order_item TYPE zpp_pack-posnr
                                   iv_pack_list        TYPE zpp_pack-pklst
                                   it_boxes            TYPE tt_boxes
                         RETURNING VALUE(rv_affected)  TYPE i.

ENDCLASS.

CLASS lhc_packing_list IMPLEMENTATION.

  METHOD split_boxes.
    SPLIT iv_list AT ';' INTO TABLE DATA(lt_raw).
    LOOP AT lt_raw INTO DATA(lv_box) WHERE table_line IS NOT INITIAL.
      APPEND CONV zboxno( lv_box ) TO rt_boxes.
    ENDLOOP.
  ENDMETHOD.

  METHOD assign_boxes.
    LOOP AT it_boxes INTO DATA(lv_box).
      " zpp_pack key is boxno + gjahr — resolve the box's year (VERIFY note 1)
      SELECT SINGLE gjahr FROM zpp_pack WHERE boxno = @lv_box INTO @DATA(lv_gjahr).
      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.
      UPDATE zpp_pack SET vbeln  = @iv_sales_order,
                          posnr  = @iv_sales_order_item,
                          pklst  = @iv_pack_list,
                          pldate = @sy-datum
        WHERE boxno = @lv_box AND gjahr = @lv_gjahr.
      IF sy-subrc = 0.
        rv_affected = rv_affected + 1.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD createPackingList.
    LOOP AT keys INTO DATA(key).
      DATA(lv_affected) = assign_boxes(
        iv_sales_order      = CONV #( key-%param-SalesOrder )
        iv_sales_order_item = CONV #( key-%param-SalesOrderItem )
        iv_pack_list        = CONV #( key-%param-PackListItem )
        it_boxes            = split_boxes( CONV #( key-%param-BoxList ) ) ).
      APPEND VALUE #( %param-BoxesAffected = lv_affected
                      %param-PackListItem  = key-%param-PackListItem
                      %param-Message       = |{ lv_affected } box(es) assigned to packing list { key-%param-PackListItem }.| )
             TO result.
    ENDLOOP.
  ENDMETHOD.

  METHOD changePackingList.
    " Same operation as create — re-assign the selected boxes to the pack list.
    LOOP AT keys INTO DATA(key).
      DATA(lv_affected) = assign_boxes(
        iv_sales_order      = CONV #( key-%param-SalesOrder )
        iv_sales_order_item = CONV #( key-%param-SalesOrderItem )
        iv_pack_list        = CONV #( key-%param-PackListItem )
        it_boxes            = split_boxes( CONV #( key-%param-BoxList ) ) ).
      APPEND VALUE #( %param-BoxesAffected = lv_affected
                      %param-PackListItem  = key-%param-PackListItem
                      %param-Message       = |{ lv_affected } box(es) re-assigned on packing list { key-%param-PackListItem }.| )
             TO result.
    ENDLOOP.
  ENDMETHOD.

  METHOD deletePackingList.
    LOOP AT keys INTO DATA(key).
      DATA(lt_boxes) = split_boxes( CONV #( key-%param-BoxList ) ).
      IF lt_boxes IS INITIAL.
        CONTINUE.
      ENDIF.

      " 1) log the current pack-list rows to ZPLISTD (soft-delete audit)
      SELECT boxno, gjahr, vbeln, posnr, pklst
        FROM zpp_pack
        FOR ALL ENTRIES IN @lt_boxes
        WHERE boxno = @lt_boxes-table_line
        INTO TABLE @DATA(lt_cur).

      DATA lt_del TYPE STANDARD TABLE OF zplistd.
      LOOP AT lt_cur INTO DATA(ls_cur).
        APPEND VALUE #( vbeln = ls_cur-vbeln
                        posnr = ls_cur-posnr
                        pklst = ls_cur-pklst
                        boxno = ls_cur-boxno ) TO lt_del.   " VERIFY note 3
      ENDLOOP.
      IF lt_del IS NOT INITIAL.
        INSERT zplistd FROM TABLE @lt_del ACCEPTING DUPLICATE KEYS.
      ENDIF.

      " 2) clear the pack-list assignment on the boxes
      DATA lv_affected TYPE i.
      CLEAR lv_affected.
      LOOP AT lt_boxes INTO DATA(lv_box).
        SELECT SINGLE gjahr FROM zpp_pack WHERE boxno = @lv_box INTO @DATA(lv_gjahr).
        IF sy-subrc <> 0.
          CONTINUE.
        ENDIF.
        UPDATE zpp_pack SET vbeln  = @space,
                            posnr  = @space,
                            pklst  = @space,
                            pldate = '00000000'
          WHERE boxno = @lv_box AND gjahr = @lv_gjahr.
        IF sy-subrc = 0.
          lv_affected = lv_affected + 1.
        ENDIF.
      ENDLOOP.

      APPEND VALUE #( %param-BoxesAffected = lv_affected
                      %param-PackListItem  = key-%param-PackListItem
                      %param-Message       = |{ lv_affected } box(es) removed; logged to ZPLISTD.| )
             TO result.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
