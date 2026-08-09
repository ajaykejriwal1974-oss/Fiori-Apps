*&---------------------------------------------------------------------*
*& Report ZFI_JOURNAL_UPLOAD
*& Frontend for ZCL_FI_JOURNAL_POST: upload a spreadsheet of journal
*& lines and post one accounting document per reference (XBLNR) via the
*& standard BAPI. Clean-core successor UI for ZF02 / ZSAL_POST.
*&
*& File columns (row 1 = header, one row per line item):
*&  BLDAT BLART BUKRS BUDAT MONAT WAERS BKTXT XBLNR BSCHL BUPLA SECCO
*&  HKONT DMBTR SGTXT KOSTL PRCTR GSBER ZUONR
*&---------------------------------------------------------------------*
REPORT zfi_journal_upload.

TYPES: BEGIN OF ty_row,
         bldat TYPE string, blart TYPE string, bukrs TYPE string,
         budat TYPE string, monat TYPE string, waers TYPE string,
         bktxt TYPE string, xblnr TYPE string, bschl TYPE string,
         bupla TYPE string, secco TYPE string, hkont TYPE string,
         dmbtr TYPE string, sgtxt TYPE string, kostl TYPE string,
         prctr TYPE string, gsber TYPE string, zuonr TYPE string,
       END OF ty_row.

DATA: gt_row TYPE STANDARD TABLE OF ty_row,
      gt_raw TYPE truxs_t_text_data.

PARAMETERS: p_file TYPE rlgrap-filename OBLIGATORY,
            p_test AS CHECKBOX DEFAULT 'X'.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_file.
  DATA lt_files TYPE filetable.
  DATA lv_rc    TYPE i.
  cl_gui_frontend_services=>file_open_dialog(
    CHANGING file_table = lt_files rc = lv_rc EXCEPTIONS OTHERS = 1 ).
  IF sy-subrc = 0.
    READ TABLE lt_files INTO DATA(ls_file) INDEX 1.
    IF sy-subrc = 0.
      p_file = ls_file-filename.
    ENDIF.
  ENDIF.

START-OF-SELECTION.

  CALL FUNCTION 'TEXT_CONVERT_XLS_TO_SAP'
    EXPORTING
      i_line_header        = 'X'
      i_tab_raw_data       = gt_raw
      i_filename           = p_file
    TABLES
      i_tab_converted_data = gt_row
    EXCEPTIONS
      conversion_failed    = 1
      OTHERS               = 2.
  IF sy-subrc <> 0 OR gt_row IS INITIAL.
    WRITE / 'Could not read the file / no data.' COLOR COL_NEGATIVE.
    RETURN.
  ENDIF.

  IF p_test = abap_true.
    WRITE: / 'Simulation (BAPI check) - untick "P_TEST" to post:' COLOR COL_TOTAL.
    SKIP.
  ENDIF.

  DATA(lo_post) = NEW zcl_fi_journal_post( ).

  " distinct references -> one document each
  DATA lt_ref TYPE STANDARD TABLE OF string.
  lt_ref = VALUE #( FOR r IN gt_row ( r-xblnr ) ).
  SORT lt_ref. DELETE ADJACENT DUPLICATES FROM lt_ref.

  LOOP AT lt_ref INTO DATA(lv_ref).
    READ TABLE gt_row INTO DATA(ls_h) WITH KEY xblnr = lv_ref.
    CHECK sy-subrc = 0.

    DATA lv_bldat TYPE bldat.
    DATA lv_budat TYPE budat.
    CALL FUNCTION 'CONVERSION_EXIT_SDATE_INPUT' EXPORTING input = ls_h-bldat IMPORTING output = lv_bldat.
    CALL FUNCTION 'CONVERSION_EXIT_SDATE_INPUT' EXPORTING input = ls_h-budat IMPORTING output = lv_budat.

    DATA(ls_hdr) = VALUE zcl_fi_journal_post=>ty_header(
      comp_code  = ls_h-bukrs
      doc_date   = lv_bldat
      pstng_date = lv_budat
      doc_type   = ls_h-blart
      currency   = ls_h-waers
      header_txt = ls_h-bktxt
      ref_doc_no = ls_h-xblnr ).

    DATA lt_item TYPE zcl_fi_journal_post=>tt_item.
    CLEAR lt_item.
    LOOP AT gt_row INTO DATA(ls_i) WHERE xblnr = lv_ref.
      DATA lv_amt TYPE dmbtr.
      lv_amt = ls_i-dmbtr.
      APPEND VALUE #( posting_key  = ls_i-bschl
                      account      = ls_i-hkont
                      amount       = lv_amt
                      item_text    = ls_i-sgtxt
                      cost_center  = ls_i-kostl
                      profit_ctr   = ls_i-prctr
                      bus_area     = ls_i-gsber
                      alloc_nmbr   = ls_i-zuonr
                      bus_place    = ls_i-bupla
                      section_code = ls_i-secco ) TO lt_item.
    ENDLOOP.

    DATA lv_belnr TYPE belnr_d.
    DATA lv_gjahr TYPE gjahr.
    DATA(lt_ret) = lo_post->post(
      EXPORTING is_header = ls_hdr it_item = lt_item iv_test = p_test
      IMPORTING ev_belnr = lv_belnr ev_fisc_year = lv_gjahr ).

    IF lv_belnr IS NOT INITIAL.
      WRITE: / lv_ref, ':', 'Document', lv_belnr, lv_gjahr, 'posted' COLOR COL_POSITIVE.
    ELSEIF p_test = abap_true AND NOT line_exists( lt_ret[ type = 'E' ] ).
      WRITE: / lv_ref, ':', 'OK (simulation - structure accepted)' COLOR COL_POSITIVE.
    ELSE.
      LOOP AT lt_ret INTO DATA(ls_m) WHERE type CA 'EAW'.
        WRITE: / lv_ref, ':', ls_m-message COLOR COL_NEGATIVE.
      ENDLOOP.
    ENDIF.
  ENDLOOP.
