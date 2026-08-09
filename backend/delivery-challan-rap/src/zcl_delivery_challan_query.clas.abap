CLASS zcl_delivery_challan_query DEFINITION
  PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES if_rap_query_provider.
ENDCLASS.

CLASS zcl_delivery_challan_query IMPLEMENTATION.
  METHOD if_rap_query_provider~select.
    " Delivery challan (read) - legacy ZDELC / ZSOL_DELIVERY_CHALLAN.
    " VEKP HUs packed onto a delivery (VPOBJKEY = the delivery/challan). Per carton the
    " box master ZPP_PACK (boxno = exidv+10(10)) carries COP/Grade/Size, net weight AND the
    " sales order. Net weight: prefer ZPP_PACK-NETWT, fall back to VEKP-NTGEW (0 on outer/
    " system HUs). Sales order comes from ZPP_PACK-VBELN (VBFA doc-flow is empty here).
    " Delivery (Object Key) is the PRIMARY filter; Grade + Sales Order narrow within it.
    DATA lr_del   TYPE RANGE OF vpobjkey.
    DATA lr_grade TYPE RANGE OF zde_gcode.
    DATA lr_so    TYPE RANGE OF vbeln_va.
    TRY.
        LOOP AT io_request->get_filter( )->get_as_ranges( ) INTO DATA(ls_r).
          CASE to_upper( ls_r-name ).
            WHEN 'CHALLANDELIVERY'. lr_del   = CORRESPONDING #( ls_r-range ).
            WHEN 'GRADE'.           lr_grade = CORRESPONDING #( ls_r-range ).
            WHEN 'SALESORDER'.      lr_so    = CORRESPONDING #( ls_r-range ).
          ENDCASE.
        ENDLOOP.
      CATCH cx_rap_query_filter_no_range.
    ENDTRY.

    DATA lt_out TYPE STANDARD TABLE OF zi_delivery_challan.
    DATA ls_out TYPE zi_delivery_challan.

    " Guard: VEKP has 4.28M rows. Require a delivery (Object Key) filter so we never
    " scan the whole table on an empty query. No delivery -> empty result.
    IF lr_del IS NOT INITIAL.
      SELECT venum, exidv, vpobjkey, ntgew, gewei
        FROM vekp
        WHERE vpobjkey IN @lr_del
        INTO TABLE @DATA(lt_hu).

      IF lt_hu IS NOT INITIAL.
        " box master (COP/grade/size/weight/sales order) - ONE batched read, not N singles
        DATA lt_box TYPE STANDARD TABLE OF zboxno.
        LOOP AT lt_hu INTO DATA(ls_h).
          APPEND ls_h-exidv+10(10) TO lt_box.
        ENDLOOP.
        SORT lt_box. DELETE ADJACENT DUPLICATES FROM lt_box.
        IF lt_box IS NOT INITIAL.
          SELECT boxno, spoolno, grade, psize, netwt, vbeln FROM zpp_pack
            FOR ALL ENTRIES IN @lt_box
            WHERE boxno = @lt_box-table_line
            INTO TABLE @DATA(lt_pk).
          SORT lt_pk BY boxno.
        ENDIF.

        LOOP AT lt_hu INTO ls_h.
          DATA(lv_box) = CONV zboxno( ls_h-exidv+10(10) ).
          CLEAR ls_out.
          ls_out-handlingunitno  = ls_h-venum.
          ls_out-challandelivery = ls_h-vpobjkey.
          ls_out-cartonno        = ls_h-exidv.
          ls_out-netweightunit   = COND #( WHEN ls_h-gewei IS NOT INITIAL THEN ls_h-gewei ELSE 'KG' ).

          READ TABLE lt_pk INTO DATA(ls_pk) WITH KEY boxno = lv_box BINARY SEARCH.
          IF sy-subrc = 0.
            ls_out-copno      = ls_pk-spoolno.
            ls_out-grade      = ls_pk-grade.
            ls_out-packsize   = ls_pk-psize.
            ls_out-salesorder = ls_pk-vbeln.
            ls_out-netweight  = COND #( WHEN ls_pk-netwt IS NOT INITIAL THEN ls_pk-netwt ELSE ls_h-ntgew ).
          ELSE.
            " no box master (outer/system HU) - fall back to the HU header weight
            ls_out-netweight  = ls_h-ntgew.
          ENDIF.

          APPEND ls_out TO lt_out.
        ENDLOOP.

        " secondary filters (narrow within the delivery)
        IF lr_grade IS NOT INITIAL.
          DELETE lt_out WHERE grade NOT IN lr_grade.
        ENDIF.
        IF lr_so IS NOT INITIAL.
          DELETE lt_out WHERE salesorder NOT IN lr_so.
        ENDIF.
      ENDIF.
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
