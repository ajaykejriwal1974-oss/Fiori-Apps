CLASS zcl_return_box_query DEFINITION
  PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES if_rap_query_provider.
ENDCLASS.

CLASS zcl_return_box_query IMPLEMENTATION.
  METHOD if_rap_query_provider~select.
    " Lists boxes packed onto RETURNS deliveries (LIKP-LFART='LR') - read side of legacy
    " ZCSD001 / ZCRPT_SD_002. Chain: LIKP -> LIPS -> VEKP+VEPO (HU) -> ZPP_PACK.
    " boxno = ALPHA_OUTPUT(exidv). Eligible = VPOBJ='12' (HU assigned to a delivery).
    " Delivery is the PRIMARY filter; Material / Plant / Eligible narrow within it.
    DATA lr_vbeln TYPE RANGE OF vbeln_vl.
    DATA lr_matnr TYPE RANGE OF matnr.
    DATA lr_werks TYPE RANGE OF werks_d.
    DATA lr_elig  TYPE RANGE OF abap_boolean.
    TRY.
        LOOP AT io_request->get_filter( )->get_as_ranges( ) INTO DATA(ls_r).
          CASE to_upper( ls_r-name ).
            WHEN 'DELIVERY'. lr_vbeln = CORRESPONDING #( ls_r-range ).
            WHEN 'MATERIAL'. lr_matnr = CORRESPONDING #( ls_r-range ).
            WHEN 'PLANT'.    lr_werks = CORRESPONDING #( ls_r-range ).
            WHEN 'ELIGIBLE'. lr_elig  = CORRESPONDING #( ls_r-range ).
          ENDCASE.
        ENDLOOP.
      CATCH cx_rap_query_filter_no_range.
    ENDTRY.

    DATA lt_out TYPE STANDARD TABLE OF zi_return_box.
    DATA ls_out TYPE zi_return_box.

    " Guard: require a returns-delivery filter so we never scan all LR deliveries /
    " 4.28M HUs on an empty query. No filter -> empty result.
    IF lr_vbeln IS NOT INITIAL.
      SELECT vbeln, lfart FROM likp
        WHERE vbeln IN @lr_vbeln
          AND lfart = 'LR'
        INTO TABLE @DATA(lt_likp).

      IF lt_likp IS NOT INITIAL.
        SELECT vbeln, posnr FROM lips
          FOR ALL ENTRIES IN @lt_likp
          WHERE vbeln = @lt_likp-vbeln
          INTO TABLE @DATA(lt_lips).

        IF lt_lips IS NOT INITIAL.
          SELECT k~venum, k~exidv, k~vpobj, p~vbeln, p~posnr
            FROM vekp AS k
            INNER JOIN vepo AS p ON p~venum = k~venum
            FOR ALL ENTRIES IN @lt_lips
            WHERE p~vbeln = @lt_lips-vbeln
              AND p~posnr = @lt_lips-posnr
            INTO TABLE @DATA(lt_hu).

          IF lt_hu IS NOT INITIAL.
            " batch box master (ZPP_PACK) - one round trip instead of N SELECT SINGLEs
            DATA lt_box TYPE STANDARD TABLE OF zboxno.
            LOOP AT lt_hu INTO DATA(ls_hu).
              APPEND |{ ls_hu-exidv ALPHA = OUT }| TO lt_box.
            ENDLOOP.
            SORT lt_box. DELETE ADJACENT DUPLICATES FROM lt_box.
            SELECT boxno, matnr, werks, gjahr, netwt, vbeln FROM zpp_pack
              FOR ALL ENTRIES IN @lt_box
              WHERE boxno = @lt_box-table_line
              INTO TABLE @DATA(lt_pk).
            SORT lt_pk BY boxno.

            " batch material texts (MAKT)
            DATA lt_mat TYPE STANDARD TABLE OF matnr.
            LOOP AT lt_pk INTO DATA(ls_pkm).
              IF ls_pkm-matnr IS NOT INITIAL.
                APPEND ls_pkm-matnr TO lt_mat.
              ENDIF.
            ENDLOOP.
            SORT lt_mat. DELETE ADJACENT DUPLICATES FROM lt_mat.
            IF lt_mat IS NOT INITIAL.
              SELECT matnr, maktx FROM makt
                FOR ALL ENTRIES IN @lt_mat
                WHERE matnr = @lt_mat-table_line
                  AND spras = @sy-langu
                INTO TABLE @DATA(lt_makt).
              SORT lt_makt BY matnr.
            ENDIF.

            LOOP AT lt_hu INTO ls_hu.
              DATA(lv_box) = CONV zboxno( |{ ls_hu-exidv ALPHA = OUT }| ).
              CLEAR ls_out.
              ls_out-boxno        = lv_box.
              ls_out-handlingunit = ls_hu-exidv.
              ls_out-delivery     = ls_hu-vbeln.
              ls_out-deliveryitem = ls_hu-posnr.
              ls_out-packobjtype  = ls_hu-vpobj.
              ls_out-eligible     = COND #( WHEN ls_hu-vpobj = '12' THEN abap_true ELSE abap_false ).
              ls_out-weightunit   = 'KG'.

              READ TABLE lt_pk INTO DATA(ls_pk) WITH KEY boxno = lv_box BINARY SEARCH.
              IF sy-subrc = 0.
                ls_out-material   = ls_pk-matnr.
                ls_out-plant      = ls_pk-werks.
                ls_out-fiscalyear = ls_pk-gjahr.
                ls_out-netweight  = ls_pk-netwt.
                ls_out-salesorder = ls_pk-vbeln.
                IF ls_pk-matnr IS NOT INITIAL.
                  READ TABLE lt_makt INTO DATA(ls_mk) WITH KEY matnr = ls_pk-matnr BINARY SEARCH.
                  IF sy-subrc = 0.
                    ls_out-materialtext = ls_mk-maktx.
                  ENDIF.
                ENDIF.
              ENDIF.

              APPEND ls_out TO lt_out.
            ENDLOOP.
          ENDIF.
        ENDIF.
      ENDIF.

      " secondary filters (narrow within the delivery)
      IF lr_matnr IS NOT INITIAL.
        DELETE lt_out WHERE material NOT IN lr_matnr.
      ENDIF.
      IF lr_werks IS NOT INITIAL.
        DELETE lt_out WHERE plant NOT IN lr_werks.
      ENDIF.
      IF lr_elig IS NOT INITIAL.
        DELETE lt_out WHERE eligible NOT IN lr_elig.
      ENDIF.
    ENDIF.

    SORT lt_out BY delivery boxno.

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
