CLASS zcl_pallet_stock_query DEFINITION
  PUBLIC FINAL
  CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES if_rap_query_provider.
ENDCLASS.

CLASS zcl_pallet_stock_query IMPLEMENTATION.
  METHOD if_rap_query_provider~select.
    " Current customer-consignment (returnable-packaging) stock per plant/customer/material.
    " Replaces legacy report ZSOL_PALLET_STOCK / tx ZPEL. Reads MSKU via ABAP Open SQL: in
    " S/4HANA the MSKU stock is materialised only through the Open-SQL redirect (NSDM), NOT
    " through a plain CDS view over MSKU (which binds to the empty base table and returns 0).
    " Plant / Customer / Material filters are pushed into the DB WHERE.
    DATA lr_werks TYPE RANGE OF werks_d.
    DATA lr_kunnr TYPE RANGE OF kunnr.
    DATA lr_matnr TYPE RANGE OF matnr.
    TRY.
        LOOP AT io_request->get_filter( )->get_as_ranges( ) INTO DATA(ls_r).
          CASE to_upper( ls_r-name ).
            WHEN 'PLANT'.    lr_werks = CORRESPONDING #( ls_r-range ).
            WHEN 'CUSTOMER'. lr_kunnr = CORRESPONDING #( ls_r-range ).
            WHEN 'MATERIAL'. lr_matnr = CORRESPONDING #( ls_r-range ).
          ENDCASE.
        ENDLOOP.
      CATCH cx_rap_query_filter_no_range.
    ENDTRY.

    SELECT FROM msku AS s
      FIELDS s~werks AS plant,
             s~kunnr AS customer,
             s~matnr AS material,
             SUM( s~kulab )                     AS unrestrictedstock,
             SUM( s~kuins )                     AS qualityinspstock,
             SUM( s~kuein )                     AS restrictedstock,
             SUM( s~kulab + s~kuins + s~kuein ) AS stockatcustomer
      WHERE s~sobkz = 'V'
        AND s~werks IN @lr_werks
        AND s~kunnr IN @lr_kunnr
        AND s~matnr IN @lr_matnr
      GROUP BY s~werks, s~kunnr, s~matnr
      INTO TABLE @DATA(lt_stock).

    DATA lt_result TYPE STANDARD TABLE OF zi_pallet_stock_ledger.

    IF lt_stock IS NOT INITIAL.
      " ---- batch the description lookups (one round trip each, not N per row) ----
      DATA lt_cust TYPE STANDARD TABLE OF kunnr.
      DATA lt_matn TYPE STANDARD TABLE OF matnr.
      LOOP AT lt_stock ASSIGNING FIELD-SYMBOL(<s0>).
        APPEND <s0>-customer TO lt_cust.
        APPEND <s0>-material TO lt_matn.
      ENDLOOP.
      SORT lt_cust. DELETE ADJACENT DUPLICATES FROM lt_cust.
      SORT lt_matn. DELETE ADJACENT DUPLICATES FROM lt_matn.

      IF lt_cust IS NOT INITIAL.
        SELECT kunnr, name1 FROM kna1
          FOR ALL ENTRIES IN @lt_cust
          WHERE kunnr = @lt_cust-table_line
          INTO TABLE @DATA(lt_kna1).
        SORT lt_kna1 BY kunnr.
      ENDIF.
      IF lt_matn IS NOT INITIAL.
        SELECT matnr, maktx FROM makt
          FOR ALL ENTRIES IN @lt_matn
          WHERE matnr = @lt_matn-table_line
            AND spras = @sy-langu
          INTO TABLE @DATA(lt_makt).
        SORT lt_makt BY matnr.
        SELECT matnr, meins FROM mara
          FOR ALL ENTRIES IN @lt_matn
          WHERE matnr = @lt_matn-table_line
          INTO TABLE @DATA(lt_mara).
        SORT lt_mara BY matnr.
      ENDIF.

      LOOP AT lt_stock ASSIGNING FIELD-SYMBOL(<s>).
        APPEND INITIAL LINE TO lt_result ASSIGNING FIELD-SYMBOL(<r>).
        <r>-plant             = <s>-plant.
        <r>-customer          = <s>-customer.
        <r>-material          = <s>-material.
        <r>-unrestrictedstock = <s>-unrestrictedstock.
        <r>-qualityinspstock  = <s>-qualityinspstock.
        <r>-restrictedstock   = <s>-restrictedstock.
        <r>-stockatcustomer   = <s>-stockatcustomer.
        READ TABLE lt_kna1 INTO DATA(ls_k) WITH KEY kunnr = <s>-customer BINARY SEARCH.
        IF sy-subrc = 0. <r>-customername = ls_k-name1. ENDIF.
        READ TABLE lt_makt INTO DATA(ls_m) WITH KEY matnr = <s>-material BINARY SEARCH.
        IF sy-subrc = 0. <r>-materialdescription = ls_m-maktx. ENDIF.
        READ TABLE lt_mara INTO DATA(ls_a) WITH KEY matnr = <s>-material BINARY SEARCH.
        IF sy-subrc = 0. <r>-baseunit = ls_a-meins. ENDIF.
      ENDLOOP.
    ENDIF.

    SORT lt_result BY customer material plant.

    IF io_request->is_total_numb_of_rec_requested( ).
      io_response->set_total_number_of_records( lines( lt_result ) ).
    ENDIF.

    IF io_request->is_data_requested( ).
      DATA(lo_paging) = io_request->get_paging( ).
      DATA(lv_offset) = lo_paging->get_offset( ).
      DATA(lv_page)   = lo_paging->get_page_size( ).
      DATA lt_page TYPE STANDARD TABLE OF zi_pallet_stock_ledger.
      IF lv_page = if_rap_query_paging=>page_size_unlimited.
        lt_page = lt_result.
      ELSE.
        LOOP AT lt_result ASSIGNING FIELD-SYMBOL(<p>) FROM lv_offset + 1.
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
