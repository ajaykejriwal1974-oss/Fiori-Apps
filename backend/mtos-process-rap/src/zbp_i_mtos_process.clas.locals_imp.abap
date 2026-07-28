CLASS lhc_zi_mtos_process DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS converttomts FOR MODIFY
      IMPORTING keys FOR ACTION MtosStock~convertToMts RESULT result.
    METHODS createphysinvdoc FOR MODIFY
      IMPORTING keys FOR ACTION MtosStock~createPhysInvDoc RESULT result.
ENDCLASS.

CLASS lhc_zi_mtos_process IMPLEMENTATION.

  METHOD converttomts.
    DATA: ls_header TYPE bapi2017_gm_head_01,
          ls_code   TYPE bapi2017_gm_code,
          lt_item   TYPE STANDARD TABLE OF bapi2017_gm_item_create,
          ls_item   TYPE bapi2017_gm_item_create,
          lt_return TYPE STANDARD TABLE OF bapiret2,
          lv_matdoc TYPE bapi2017_gm_head_ret-mat_doc,
          lv_year   TYPE bapi2017_gm_head_ret-doc_year.

    LOOP AT keys INTO DATA(ls_key).
      CLEAR: lt_item, lt_return, lv_matdoc, lv_year, ls_item.
      ls_item-material_long  = ls_key-%param-Material.
      ls_item-plant          = ls_key-%param-Plant.
      ls_item-move_type      = '411'.
      ls_item-spec_stock     = 'E'.
      ls_item-val_sales_ord  = |{ ls_key-%param-SalesOrder ALPHA = IN }|.
      ls_item-val_s_ord_item = ls_key-%param-SalesOrderItem.
      ls_item-entry_qnt      = ls_key-%param-Quantity.
      ls_item-entry_uom      = ls_key-%param-BaseUnit.
      APPEND ls_item TO lt_item.

      ls_header-pstng_date = sy-datum.
      ls_header-doc_date   = sy-datum.
      ls_code-gm_code      = '04'.

      CALL FUNCTION 'BAPI_GOODSMVT_CREATE'
        EXPORTING  goodsmvt_header  = ls_header
                   goodsmvt_code    = ls_code
        IMPORTING  materialdocument = lv_matdoc
                   matdocumentyear  = lv_year
        TABLES     goodsmvt_item    = lt_item
                   return           = lt_return.

      READ TABLE lt_return INTO DATA(ls_err) WITH KEY type = 'E'.
      IF sy-subrc = 0.
        INSERT VALUE #( %cid = ls_key-%cid %param-message = ls_err-message ) INTO TABLE result.
      ELSE.
        INSERT VALUE #( %cid = ls_key-%cid
          %param-materialdocument = lv_matdoc
          %param-message = |MTO->MTS posted, material document { lv_matdoc }/{ lv_year }.| ) INTO TABLE result.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD createphysinvdoc.
    DATA: ls_head   TYPE bapi_physinv_create_head,
          lt_items  TYPE STANDARD TABLE OF bapi_physinv_create_items,
          ls_it     TYPE bapi_physinv_create_items,
          lt_return TYPE STANDARD TABLE OF bapiret2,
          lv_iblnr  TYPE char10.

    LOOP AT keys INTO DATA(ls_key).
      CLEAR: lt_items, lt_return, lv_iblnr, ls_head.
      ls_head-plant     = ls_key-%param-Plant.
      ls_head-stge_loc  = ls_key-%param-StorageLocation.
      ls_head-doc_date  = sy-datum.
      ls_head-plan_date = sy-datum.

      SPLIT ls_key-%param-ItemList AT ';' INTO TABLE DATA(lt_pairs).
      LOOP AT lt_pairs INTO DATA(lv_pair).
        CONDENSE lv_pair.
        CHECK lv_pair IS NOT INITIAL.
        SPLIT lv_pair AT '=' INTO DATA(lv_mat) DATA(lv_batch).
        CLEAR ls_it.
        ls_it-material_long = lv_mat.
        ls_it-batch         = lv_batch.
        ls_it-stock_type    = '1'.
        APPEND ls_it TO lt_items.
      ENDLOOP.

      IF lt_items IS INITIAL.
        INSERT VALUE #( %cid = ls_key-%cid %param-message = |No items in list.| ) INTO TABLE result.
        CONTINUE.
      ENDIF.

      CALL FUNCTION 'BAPI_MATPHYSINV_CREATE'
        EXPORTING  head   = ls_head
        TABLES     items  = lt_items
                   return = lt_return.

      READ TABLE lt_return INTO DATA(ls_err) WITH KEY type = 'E'.
      IF sy-subrc = 0.
        INSERT VALUE #( %cid = ls_key-%cid %param-message = ls_err-message ) INTO TABLE result.
      ELSE.
        LOOP AT lt_return INTO DATA(ls_s) WHERE type CA 'SI'.
          IF ls_s-message_v1 IS NOT INITIAL.
            lv_iblnr = ls_s-message_v1.
          ENDIF.
        ENDLOOP.
        INSERT VALUE #( %cid = ls_key-%cid
          %param-physinvdocument = lv_iblnr
          %param-message = |Physical inventory document { lv_iblnr } created.| ) INTO TABLE result.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.

CLASS lsc_zi_mtos_process DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PROTECTED SECTION.
    METHODS save REDEFINITION.
ENDCLASS.

CLASS lsc_zi_mtos_process IMPLEMENTATION.
  METHOD save.
  ENDMETHOD.
ENDCLASS.
