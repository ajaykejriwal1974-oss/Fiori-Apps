CLASS zcl_delivery_challan_query DEFINITION
  PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES if_rap_query_provider.
ENDCLASS.

CLASS zcl_delivery_challan_query IMPLEMENTATION.
  METHOD if_rap_query_provider~select.
    " Delivery challan (read). VEKP HUs packed onto a delivery (VPOBJKEY = the
    " delivery/challan); per carton the box master ZPP_PACK (boxno = exidv+10(10))
    " carries COP/Grade/Size, net weight and the sales order. Creator = VEKP ERDAT/
    " ERNAM, name resolved via USER_ADDR-NAME_TEXTC.
    " Primary filter: ChallanDelivery (list) OR HandlingUnitNo (object-page read-by-key).
    " Secondary (narrow within): Grade, SalesOrder, CreatedOn, CreatedBy.
    DATA lr_del   TYPE RANGE OF vpobjkey.
    DATA lr_hu    TYPE RANGE OF venum.
    DATA lr_grade TYPE RANGE OF zde_gcode.
    DATA lr_so    TYPE RANGE OF vbeln_va.
    DATA lr_erdat TYPE RANGE OF erdat.
    DATA lr_ernam TYPE RANGE OF ernam.
    DATA lr_werks TYPE RANGE OF werks_d.
    DATA lr_matnr TYPE RANGE OF matnr.
    DATA lr_charg TYPE RANGE OF charg_d.
    DATA lr_bukrs TYPE RANGE OF bukrs.

    TRY.
        LOOP AT io_request->get_filter( )->get_as_ranges( ) INTO DATA(ls_r).
          CASE to_upper( ls_r-name ).
            WHEN 'CHALLANDELIVERY'. lr_del   = CORRESPONDING #( ls_r-range ).
            WHEN 'HANDLINGUNITNO'.  lr_hu    = CORRESPONDING #( ls_r-range ).
            WHEN 'GRADE'.           lr_grade = CORRESPONDING #( ls_r-range ).
            WHEN 'SALESORDER'.      lr_so    = CORRESPONDING #( ls_r-range ).
            WHEN 'CREATEDON'.       lr_erdat = CORRESPONDING #( ls_r-range ).
            WHEN 'CREATEDBY'.       lr_ernam = CORRESPONDING #( ls_r-range ).
            WHEN 'COMPANYCODE'.     lr_bukrs = CORRESPONDING #( ls_r-range ).
            WHEN 'PLANT'.           lr_werks = CORRESPONDING #( ls_r-range ).
            WHEN 'MATERIAL'.        lr_matnr = CORRESPONDING #( ls_r-range ).
            WHEN 'BATCH'.           lr_charg = CORRESPONDING #( ls_r-range ).
          ENDCASE.
        ENDLOOP.
      CATCH cx_rap_query_filter_no_range.
    ENDTRY.

    " Free-text search - see ZCL_PALLET_STOCK_QUERY for the pattern.
    DATA lv_search TYPE string.
    TRY.
        lv_search = to_upper( io_request->get_search_expression( ) ).
      CATCH cx_root.
        CLEAR lv_search.
    ENDTRY.

    TYPES: BEGIN OF ty_hu,
             venum    TYPE vekp-venum,
             exidv    TYPE vekp-exidv,
             vpobjkey TYPE vekp-vpobjkey,
             ntgew    TYPE vekp-ntgew,
             gewei    TYPE vekp-gewei,
             erdat    TYPE vekp-erdat,
             ernam    TYPE vekp-ernam,
           END OF ty_hu.
    DATA lt_hu  TYPE STANDARD TABLE OF ty_hu.
    DATA lv_box TYPE zboxno.

    DATA lt_out TYPE STANDARD TABLE OF zi_delivery_challan.
    DATA ls_out TYPE zi_delivery_challan.

    " Guard: VEKP has 4.28M rows. Require a delivery OR a handling-unit key so we
    " never scan the whole table.
    IF lr_hu IS NOT INITIAL.
      SELECT venum, exidv, vpobjkey, ntgew, gewei, erdat, ernam
        FROM vekp WHERE venum IN @lr_hu INTO TABLE @lt_hu.
    ELSEIF lr_del IS NOT INITIAL.
      SELECT venum, exidv, vpobjkey, ntgew, gewei, erdat, ernam
        FROM vekp WHERE vpobjkey IN @lr_del INTO TABLE @lt_hu.
    ENDIF.

    IF lt_hu IS NOT INITIAL.
      " box master (COP/grade/size/weight/sales order) - one batched read
      DATA lt_box TYPE STANDARD TABLE OF zboxno.
      LOOP AT lt_hu INTO DATA(ls_h).
        APPEND ls_h-exidv+10(10) TO lt_box.
      ENDLOOP.
      SORT lt_box. DELETE ADJACENT DUPLICATES FROM lt_box.
      IF lt_box IS NOT INITIAL.
        SELECT boxno, spoolno, grade, psize, netwt, vbeln, werks, matnr, mergno FROM zpp_pack
          FOR ALL ENTRIES IN @lt_box
          WHERE boxno = @lt_box-table_line
          INTO TABLE @DATA(lt_pk).
        SORT lt_pk BY boxno.
        " plant -> company code (valuation area = plant on this system)
        IF lt_pk IS NOT INITIAL.
          SELECT bwkey, bukrs FROM t001k
            FOR ALL ENTRIES IN @lt_pk
            WHERE bwkey = @lt_pk-werks
            INTO TABLE @DATA(lt_cc).
          SORT lt_cc BY bwkey.
        ENDIF.
      ENDIF.

      " creator full name (ERNAM -> USER_ADDR-NAME_TEXTC)
      SELECT bname, name_textc FROM user_addr
        FOR ALL ENTRIES IN @lt_hu
        WHERE bname = @lt_hu-ernam
        INTO TABLE @DATA(lt_name).
      SORT lt_name BY bname.

      LOOP AT lt_hu INTO ls_h.
        lv_box = ls_h-exidv+10(10).
        CLEAR ls_out.
        ls_out-handlingunitno  = ls_h-venum.
        ls_out-challandelivery = ls_h-vpobjkey.
        ls_out-cartonno        = ls_h-exidv.
        ls_out-createdon       = ls_h-erdat.
        ls_out-createdby       = ls_h-ernam.
        ls_out-netweightunit   = COND #( WHEN ls_h-gewei IS NOT INITIAL THEN ls_h-gewei ELSE 'KG' ).

        READ TABLE lt_name INTO DATA(ls_name) WITH KEY bname = ls_h-ernam BINARY SEARCH.
        IF sy-subrc = 0.
          ls_out-createdbyname = ls_name-name_textc.
        ENDIF.

        READ TABLE lt_pk INTO DATA(ls_pk) WITH KEY boxno = lv_box BINARY SEARCH.
        IF sy-subrc = 0.
          ls_out-copno      = ls_pk-spoolno.
          ls_out-grade      = ls_pk-grade.
          ls_out-packsize   = ls_pk-psize.
          ls_out-salesorder = ls_pk-vbeln.
          ls_out-plant      = ls_pk-werks.
          ls_out-material   = ls_pk-matnr.
          ls_out-batch      = ls_pk-mergno.
          READ TABLE lt_cc INTO DATA(ls_cc) WITH KEY bwkey = ls_pk-werks BINARY SEARCH.
          IF sy-subrc = 0.
            ls_out-companycode = ls_cc-bukrs.
          ENDIF.
          ls_out-netweight  = COND #( WHEN ls_pk-netwt IS NOT INITIAL THEN ls_pk-netwt ELSE ls_h-ntgew ).
        ELSE.
          ls_out-netweight  = ls_h-ntgew.
        ENDIF.

        APPEND ls_out TO lt_out.
      ENDLOOP.

      " secondary filters (narrow within the delivery / HU)
      IF lr_grade IS NOT INITIAL.
        DELETE lt_out WHERE grade NOT IN lr_grade.
      ENDIF.
      IF lr_so IS NOT INITIAL.
        DELETE lt_out WHERE salesorder NOT IN lr_so.
      ENDIF.
      IF lr_erdat IS NOT INITIAL.
        DELETE lt_out WHERE createdon NOT IN lr_erdat.
      ENDIF.
      IF lr_ernam IS NOT INITIAL.
        DELETE lt_out WHERE createdby NOT IN lr_ernam.
      ENDIF.
      IF lr_bukrs IS NOT INITIAL.
        DELETE lt_out WHERE companycode NOT IN lr_bukrs.
      ENDIF.
      IF lr_werks IS NOT INITIAL.
        DELETE lt_out WHERE plant NOT IN lr_werks.
      ENDIF.
      IF lr_matnr IS NOT INITIAL.
        DELETE lt_out WHERE material NOT IN lr_matnr.
      ENDIF.
      IF lr_charg IS NOT INITIAL.
        DELETE lt_out WHERE batch NOT IN lr_charg.
      ENDIF.
    ENDIF.

    " Search the fields marked @Search.defaultSearchElement, after the secondary
    " filters and before the record count so the count matches what is shown.
    IF lv_search IS NOT INITIAL.
      DELETE lt_out WHERE cartonno        NP |*{ lv_search }*|
                      AND challandelivery NP |*{ lv_search }*|
                      AND material        NP |*{ lv_search }*|
                      AND batch           NP |*{ lv_search }*|
                      AND copno           NP |*{ lv_search }*|.
    ENDIF.

    SORT lt_out BY challandelivery cartonno.

    IF io_request->is_total_numb_of_rec_requested( ).
      io_response->set_total_number_of_records( lines( lt_out ) ).
    ENDIF.
    IF io_request->is_data_requested( ).
      DATA(lo_paging) = io_request->get_paging( ).
      DATA(lv_offset) = lo_paging->get_offset( ).
      DATA(lv_page)   = lo_paging->get_page_size( ).
      DATA lt_page LIKE lt_out.
      IF lv_page = if_rap_query_paging=>page_size_unlimited.
        lt_page = lt_out.
      ELSE.
        LOOP AT lt_out ASSIGNING FIELD-SYMBOL(<p>) FROM lv_offset + 1.
          APPEND <p> TO lt_page.
          IF lines( lt_page ) >= lv_page.
            EXIT.
          ENDIF.
        ENDLOOP.
      ENDIF.
      io_response->set_data( lt_page ).
    ENDIF.
  ENDMETHOD.
ENDCLASS.
