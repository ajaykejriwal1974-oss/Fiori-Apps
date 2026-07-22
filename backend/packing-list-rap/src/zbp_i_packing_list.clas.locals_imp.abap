*"* Local implementation for the Packing List behavior (unmanaged).
*"* Scaffold — the three static actions are stubbed. Fill each VERIFY/TODO spot
*"* against the real tables (ZSOL_HUDISPATCH / ZPP_PACK / ZPLISTD) before release,
*"* the same way the dispatch-correction behavior pool is completed.

CLASS lhc_packing_list DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS createPackingList FOR MODIFY
      IMPORTING keys FOR ACTION PackingList~createPackingList RESULT result.

    METHODS changePackingList FOR MODIFY
      IMPORTING keys FOR ACTION PackingList~changePackingList RESULT result.

    METHODS deletePackingList FOR MODIFY
      IMPORTING keys FOR ACTION PackingList~deletePackingList RESULT result.

    "  Helper: split 'BOX1;BOX2;BOX3' into a box-number range table.
    METHODS split_boxes IMPORTING iv_list         TYPE string
                        RETURNING VALUE(rt_boxes) TYPE STANDARD TABLE OF zboxno WITH EMPTY KEY.

ENDCLASS.

CLASS lhc_packing_list IMPLEMENTATION.

  METHOD split_boxes.
    SPLIT iv_list AT ';' INTO TABLE DATA(lt_raw).
    LOOP AT lt_raw INTO DATA(lv_box) WHERE table_line IS NOT INITIAL.
      APPEND CONV zboxno( lv_box ) TO rt_boxes.
    ENDLOOP.
  ENDMETHOD.

  METHOD createPackingList.
    LOOP AT keys INTO DATA(key).
      DATA(lt_boxes) = split_boxes( CONV #( key-%param-BoxList ) ).

      " TODO(create): allocate the next PackListItem for key-%param-SalesOrder,
      "   then insert one ZSOL_HUDISPATCH row per box (SO, SO_ITEM, PCK_LST, BOXNO,
      "   STATUS, ERDAT/TIME = sy-datum/uzeit). VERIFY the pack-list numbering rule
      "   (per sales order vs per item) against ZSD_PACKING_LIST_01.

      APPEND VALUE #( %param-BoxesAffected = lines( lt_boxes )
                      %param-PackListItem  = key-%param-PackListItem
                      %param-Message       = |Packing list created (scaffold — wire ZSOL_HUDISPATCH insert).| )
             TO result.
    ENDLOOP.
  ENDMETHOD.

  METHOD changePackingList.
    LOOP AT keys INTO DATA(key).
      DATA(lt_boxes) = split_boxes( CONV #( key-%param-BoxList ) ).

      " TODO(change): re-assign the given boxes to key-%param-PackListItem /
      "   key-%param-Status via UPDATE on ZSOL_HUDISPATCH. VERIFY whether a box may
      "   move between pack lists (ZSD_PACKING_LIST_01 change logic).

      APPEND VALUE #( %param-BoxesAffected = lines( lt_boxes )
                      %param-PackListItem  = key-%param-PackListItem
                      %param-Message       = |Packing list changed (scaffold — wire ZSOL_HUDISPATCH update).| )
             TO result.
    ENDLOOP.
  ENDMETHOD.

  METHOD deletePackingList.
    LOOP AT keys INTO DATA(key).
      DATA(lt_boxes) = split_boxes( CONV #( key-%param-BoxList ) ).

      " TODO(delete): move the pack-list rows to ZPLISTD (soft delete) then remove
      "   from ZSOL_HUDISPATCH — mirror ZSD_PACKING_LIST_01 delete. VERIFY the
      "   ZPLISTD key (VBELN + POSNR + PKLST + BOXNO) and audit fields.

      APPEND VALUE #( %param-BoxesAffected = lines( lt_boxes )
                      %param-PackListItem  = key-%param-PackListItem
                      %param-Message       = |Packing list deleted (scaffold — wire ZPLISTD move + delete).| )
             TO result.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
