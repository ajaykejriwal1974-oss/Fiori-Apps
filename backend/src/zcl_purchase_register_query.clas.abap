CLASS zcl_purchase_register_query DEFINITION
  PUBLIC FINAL
  CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES if_rap_query_provider.
ENDCLASS.

CLASS zcl_purchase_register_query IMPLEMENTATION.
  METHOD if_rap_query_provider~select.
    " GST purchase register (invoice grain) - replaces legacy report ZRPT_PREG_IPL / tx ZPUREG.
    " Spine: RBKP (MM invoice header) -> BKPF (FI accounting doc) -> BSET (tax lines).
    " Reconciled against ZRPT_PREG_IPL (2026-08-06):
    "  - Tax  = BSET-HWSTE (LOCAL/INR currency), matching the legacy (NOT FWSTE).
    "  - Base = BSET-HWBAS (true taxable base), taken ONCE per tax group (TXGRP) to avoid
    "           double-counting across the CGST/SGST lines that share one base.
    "  - Sign = credit side reverses tax + base. Legacy derives this from RBKP-XRECH
    "           (invoice / subsequent-debit = debit side, +) vs blank (credit memo /
    "           subsequent-credit, -). A vorgang-1 line posted as a credit (BSET shkzg='H')
    "           negates just that line's tax.
    "  - Active docs only: exclude reversed invoices (RBKP-STBLG not initial).
    " Tax condition types: CGST = JICG/JICN, SGST = JISG/JISN, IGST = JIIG/JIIN;
    " reverse-charge (RCM) JICR/JISR/JIIR reported SEPARATELY (legacy lumps them ->
    " legacy CGST = my CGSTAmount + RCMCGSTAmount).
    " PERF: BSET is read into a SORTED table keyed (bukrs,belnr,gjahr,txgrp) so the
    " per-invoice LOOP...WHERE uses a binary-search access path (was a full linear scan
    " on a standard table -> O(invoices x taxlines) -> timeout on broad filters).

    " ---- filters from the request (so we never scan all of RBKP) ----
    DATA: lr_bukrs TYPE RANGE OF bukrs,
          lr_belnr TYPE RANGE OF re_belnr,
          lr_budat TYPE RANGE OF budat,
          lr_gjahr TYPE RANGE OF gjahr,
          lr_xblnr TYPE RANGE OF xblnr1,
          lr_lifnr TYPE RANGE OF lifnr.
    TRY.
        DATA(lt_ranges) = io_request->get_filter( )->get_as_ranges( ).
        LOOP AT lt_ranges INTO DATA(ls_range).
          CASE to_upper( ls_range-name ).
            WHEN 'COMPANYCODE'.     lr_bukrs = CORRESPONDING #( ls_range-range ).
            WHEN 'MMINVOICENO'.     lr_belnr = CORRESPONDING #( ls_range-range ).
            WHEN 'POSTINGDATE'.     lr_budat = CORRESPONDING #( ls_range-range ).
            WHEN 'FISCALYEAR'.      lr_gjahr = CORRESPONDING #( ls_range-range ).
            WHEN 'VENDORINVOICENO'. lr_xblnr = CORRESPONDING #( ls_range-range ).
            WHEN 'SUPPLIER'.        lr_lifnr = CORRESPONDING #( ls_range-range ).
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

    DATA lt_result TYPE STANDARD TABLE OF zi_purchase_register.
    DATA lt_bset   TYPE SORTED TABLE OF bset WITH NON-UNIQUE KEY bukrs belnr gjahr txgrp.

    " Guard: require at least one selection field. RBKP is huge; an unfiltered query
    " would scan every RE invoice and time out. No filter -> empty result.
    IF lr_bukrs IS NOT INITIAL OR lr_belnr IS NOT INITIAL OR lr_budat IS NOT INITIAL
       OR lr_gjahr IS NOT INITIAL OR lr_xblnr IS NOT INITIAL OR lr_lifnr IS NOT INITIAL.

      " ---- MM invoices (RE = invoice receipt), active (not reversed) ----
      SELECT FROM rbkp
        FIELDS bukrs, belnr, gjahr, budat, bldat, xblnr, lifnr, waers, rmwwr, xrech
        WHERE bukrs IN @lr_bukrs
          AND belnr IN @lr_belnr
          AND budat IN @lr_budat
          AND gjahr IN @lr_gjahr
          AND xblnr IN @lr_xblnr
          AND lifnr IN @lr_lifnr
          AND blart  = 'RE'
          AND stblg  = @space
        INTO TABLE @DATA(lt_rbkp).

      IF lt_rbkp IS NOT INITIAL.
        DATA lt_awkey TYPE STANDARD TABLE OF bkpf-awkey.
        LOOP AT lt_rbkp INTO DATA(ls_rb).
          APPEND |{ ls_rb-belnr }{ ls_rb-gjahr }| TO lt_awkey.
        ENDLOOP.
        SORT lt_awkey. DELETE ADJACENT DUPLICATES FROM lt_awkey.

        SELECT FROM bkpf
          FIELDS bukrs, belnr, gjahr, awkey
          FOR ALL ENTRIES IN @lt_awkey
          WHERE awtyp = 'RMRP'
            AND awkey = @lt_awkey-table_line
            AND blart = 'RE'
          INTO TABLE @DATA(lt_bkpf).
        SORT lt_bkpf BY awkey.

        IF lt_bkpf IS NOT INITIAL.
          SELECT bukrs, belnr, gjahr, txgrp, kschl, hwste, hwbas, shkzg
            FROM bset
            FOR ALL ENTRIES IN @lt_bkpf
            WHERE bukrs = @lt_bkpf-bukrs
              AND belnr = @lt_bkpf-belnr
              AND gjahr = @lt_bkpf-gjahr
            INTO CORRESPONDING FIELDS OF TABLE @lt_bset.
        ENDIF.

        SELECT FROM lfa1
          FIELDS lifnr, name1, stcd3
          FOR ALL ENTRIES IN @lt_rbkp
          WHERE lifnr = @lt_rbkp-lifnr
          INTO TABLE @DATA(lt_lfa1).
        SORT lt_lfa1 BY lifnr.

        LOOP AT lt_rbkp INTO ls_rb.
          DATA(lv_awkey) = CONV bkpf-awkey( |{ ls_rb-belnr }{ ls_rb-gjahr }| ).

          " credit side (credit memo / subsequent credit; XRECH blank) reverses tax + base
          DATA(lv_sign) = COND i( WHEN ls_rb-xrech IS INITIAL THEN -1 ELSE 1 ).

          DATA ls_out TYPE zi_purchase_register.
          CLEAR ls_out.
          ls_out-companycode     = ls_rb-bukrs.
          ls_out-mminvoiceno     = ls_rb-belnr.
          ls_out-fiscalyear      = ls_rb-gjahr.
          ls_out-postingdate     = ls_rb-budat.
          ls_out-documentdate    = ls_rb-bldat.
          ls_out-vendorinvoiceno = ls_rb-xblnr.
          ls_out-supplier        = ls_rb-lifnr.
          ls_out-currency        = ls_rb-waers.
          ls_out-grossamount     = ls_rb-rmwwr.

          READ TABLE lt_lfa1 INTO DATA(ls_v) WITH KEY lifnr = ls_rb-lifnr BINARY SEARCH.
          IF sy-subrc = 0.
            ls_out-suppliername  = ls_v-name1.
            ls_out-suppliergstin = ls_v-stcd3.
          ENDIF.

          DATA: lv_base     TYPE p LENGTH 15 DECIMALS 2,
                lv_last_grp TYPE bset-txgrp.
          CLEAR: lv_base, lv_last_grp.

          READ TABLE lt_bkpf INTO DATA(ls_fi) WITH KEY awkey = lv_awkey BINARY SEARCH.
          IF sy-subrc = 0.
            LOOP AT lt_bset INTO DATA(ls_t)
                 WHERE bukrs = ls_fi-bukrs AND belnr = ls_fi-belnr AND gjahr = ls_fi-gjahr.

              " tax base (HWBAS) once per tax group - the CGST/SGST lines share one base
              IF ls_t-txgrp <> lv_last_grp.
                lv_base     = lv_base + ls_t-hwbas.
                lv_last_grp = ls_t-txgrp.
              ENDIF.

              " per-line tax sign: debit-invoice line posted as credit negates just that line
              DATA(lv_tsign) = COND i(
                WHEN ls_rb-xrech IS INITIAL                          THEN -1
                WHEN ls_rb-xrech IS NOT INITIAL AND ls_t-shkzg = 'H' THEN -1
                ELSE 1 ).

              CASE ls_t-kschl.
                WHEN 'JICG' OR 'JICN'. ls_out-cgstamount    = ls_out-cgstamount    + lv_tsign * ls_t-hwste.
                WHEN 'JISG' OR 'JISN'. ls_out-sgstamount    = ls_out-sgstamount    + lv_tsign * ls_t-hwste.
                WHEN 'JIIG' OR 'JIIN'. ls_out-igstamount    = ls_out-igstamount    + lv_tsign * ls_t-hwste.
                WHEN 'JICR'.           ls_out-rcmcgstamount = ls_out-rcmcgstamount + lv_tsign * ls_t-hwste.
                WHEN 'JISR'.           ls_out-rcmsgstamount = ls_out-rcmsgstamount + lv_tsign * ls_t-hwste.
                WHEN 'JIIR'.           ls_out-rcmigstamount = ls_out-rcmigstamount + lv_tsign * ls_t-hwste.
              ENDCASE.
            ENDLOOP.
          ENDIF.

          ls_out-baseamount  = lv_sign * lv_base.
          ls_out-totaltax    = ls_out-cgstamount    + ls_out-sgstamount    + ls_out-igstamount.
          ls_out-rcmtotaltax = ls_out-rcmcgstamount + ls_out-rcmsgstamount + ls_out-rcmigstamount.
          APPEND ls_out TO lt_result.
        ENDLOOP.
      ENDIF.

    ENDIF.

    " Search the fields marked @Search.defaultSearchElement, before the record
    " count so the count matches what is shown.
    IF lv_search IS NOT INITIAL.
      DELETE lt_result WHERE mminvoiceno     NP |*{ lv_search }*|
                         AND vendorinvoiceno NP |*{ lv_search }*|
                         AND supplier        NP |*{ lv_search }*|
                         AND suppliername    NP |*{ lv_search }*|
                         AND suppliergstin   NP |*{ lv_search }*|.
    ENDIF.

    SORT lt_result BY companycode postingdate mminvoiceno.

    IF io_request->is_total_numb_of_rec_requested( ).
      io_response->set_total_number_of_records( lines( lt_result ) ).
    ENDIF.
    IF io_request->is_data_requested( ).
      DATA(lo_paging) = io_request->get_paging( ).
      DATA(lv_offset) = lo_paging->get_offset( ).
      DATA(lv_page)   = lo_paging->get_page_size( ).
      DATA lt_page TYPE STANDARD TABLE OF zi_purchase_register.
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
