*&---------------------------------------------------------------------*
*&  Include           ZRPT_SALES_UPLOAD_FR
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Form  UPLOAD_FILE
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM upload_file .
  DATA: strleng TYPE i.
  DATA: loc_filename TYPE rlgrap-filename,
        filename     TYPE string,
        v_result     TYPE i.
  FIELD-SYMBOLS: <f1> TYPE any.
  CALL FUNCTION 'SAPGUI_PROGRESS_INDICATOR'
    EXPORTING
      percentage = 100
      text       = 'Uploading File'.
  loc_filename = p_file.
  CALL FUNCTION 'ALSM_EXCEL_TO_INTERNAL_TABLE'
    EXPORTING
      filename                = loc_filename
      i_begin_col             = 1
      i_begin_row             = 2
      i_end_col               = 18
      i_end_row               = 65536
    TABLES
      intern                  = it_excel
    EXCEPTIONS
      inconsistent_parameters = 1
      upload_ole              = 2
      OTHERS                  = 3.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ELSE.
    LOOP AT it_excel INTO wa_excel.
      ASSIGN COMPONENT wa_excel-col OF STRUCTURE gw_data TO <f1>.
      IF sy-subrc = 0.
        <f1> = wa_excel-value.
      ENDIF.
      AT END OF row.
        APPEND  gw_data TO  gt_data.
        CLEAR:  gw_data.
      ENDAT.
    ENDLOOP.
  ENDIF.
  IF gt_data[] IS INITIAL.
    MESSAGE i000(8i) WITH 'Data does not exist in file.'.
  ELSE.
*  filename = p_file.
*    CALL METHOD cl_gui_frontend_services=>file_delete
*      EXPORTING
*        filename = filename
*      CHANGING
*        rc       = v_result.
    CALL METHOD cl_gui_frontend_services=>file_copy
      EXPORTING
        source               = 'c:\users\admin\desktop\hsm\scanning\SMKGPL_307_12_55.csv'
        destination          = 'c:\users\admin\desktop\hsm\output\sap\SMKGPL_307_12_55.csv'
*       overwrite            = SPACE
      EXCEPTIONS
        cntl_error           = 1
        error_no_gui         = 2
        wrong_parameter      = 3
        disk_full            = 4
        access_denied        = 5
        file_not_found       = 6
        destination_exists   = 7
        unknown_error        = 8
        path_not_found       = 9
        disk_write_protect   = 10
        drive_not_ready      = 11
        not_supported_by_gui = 12
        OTHERS               = 13.
    IF sy-subrc EQ 0.
      CALL METHOD cl_gui_frontend_services=>file_delete
        EXPORTING
          filename             = 'c:\users\admin\desktop\hsm\scanning\SMKGPL_307_12_55.csv'
        CHANGING
          rc                   = v_result
        EXCEPTIONS
          file_delete_failed   = 1
          cntl_error           = 2
          error_no_gui         = 3
          file_not_found       = 4
          access_denied        = 5
          unknown_error        = 6
          not_supported_by_gui = 7
          wrong_parameter      = 8
          OTHERS               = 9.
    ENDIF.
*
*  IF SY-SUBRC <> 0.
*      " MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
*      "            WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
*  ENDIF.
  ENDIF.
ENDFORM.                    " UPLOAD_FILE
*&---------------------------------------------------------------------*
*&      Form  BUILD_FIELDCATALOG
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM build_fieldcatalog .
  DATA: cnt TYPE i.
  CLEAR: fieldcatalog[].
  ADD 1 TO cnt.
  fieldcatalog-fieldname    = 'CHK'.
  fieldcatalog-tabname      = 'GT_FINAL'.
  fieldcatalog-col_pos      = cnt.
  fieldcatalog-checkbox     = 'X'.
  fieldcatalog-edit         = 'X'.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR  fieldcatalog.
  ADD 1 TO cnt.
  fieldcatalog-fieldname     = 'ICONID'.
  fieldcatalog-tabname       = 'GT_FINAL'.
  fieldcatalog-seltext_m     = 'Status'.
  fieldcatalog-ddictxt       = 'M'.
  fieldcatalog-col_pos       = cnt.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR  fieldcatalog.
  ADD 1 TO cnt.
  fieldcatalog-fieldname     = 'VBELN'.
  fieldcatalog-tabname       = 'GT_FINAL'.
  fieldcatalog-seltext_m     = 'Sales Order'.
  fieldcatalog-ref_tabname   = 'VBAP'.
  fieldcatalog-ref_fieldname = 'VBELN'.
  fieldcatalog-ddictxt       = 'M'.
  fieldcatalog-col_pos       = cnt.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR  fieldcatalog.
  ADD 1 TO cnt.
  fieldcatalog-fieldname     = 'POSNR'.
  fieldcatalog-tabname       = 'GT_FINAL'.
  fieldcatalog-seltext_m     = 'Item'.
  fieldcatalog-ref_tabname   = 'VBAP'.
  fieldcatalog-ref_fieldname = 'POSNR'.
  fieldcatalog-ddictxt       = 'M'.
  fieldcatalog-col_pos       = cnt.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR  fieldcatalog.
  ADD 1 TO cnt.
  fieldcatalog-fieldname     = 'PKLST'.
  fieldcatalog-tabname       = 'GT_FINAL'.
  fieldcatalog-seltext_m     = 'Item'.
  fieldcatalog-ref_tabname   = 'ZPP_PACK'.
  fieldcatalog-ref_fieldname = 'PKLST'.
  fieldcatalog-ddictxt       = 'M'.
  fieldcatalog-col_pos       = cnt.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR  fieldcatalog.
  ADD 1 TO cnt.
  fieldcatalog-fieldname    = 'BOXNO'.
  fieldcatalog-tabname      = 'GT_FINAL'.
  fieldcatalog-seltext_m    = 'Box No.'.
  fieldcatalog-col_pos      = cnt.
  fieldcatalog-outputlen    = 10.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR  fieldcatalog.
  ADD 1 TO cnt.
  fieldcatalog-fieldname     = 'WERKS'.
  fieldcatalog-tabname       = 'GT_FINAL'.
  fieldcatalog-seltext_m     = 'Plant'.
  fieldcatalog-ref_tabname   = 'ZPP_PACK'.
  fieldcatalog-ref_fieldname = 'WERKS'.
  fieldcatalog-col_pos       = cnt.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR  fieldcatalog.
  ADD 1 TO cnt.
  fieldcatalog-fieldname     = 'LGORT'.
  fieldcatalog-tabname       = 'GT_FINAL'.
  fieldcatalog-ref_tabname   = 'ZPP_PACK'.
  fieldcatalog-ref_fieldname = 'LGORT'.
  fieldcatalog-col_pos       = cnt.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR  fieldcatalog.
  ADD 1 TO cnt.
  fieldcatalog-fieldname     = 'MATNR'.
  fieldcatalog-tabname       = 'GT_FINAL'.
  fieldcatalog-ref_tabname   = 'MARA'.
  fieldcatalog-ref_fieldname = 'MATNR'.
  fieldcatalog-col_pos       = cnt.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR  fieldcatalog.
  ADD 1 TO cnt.
  fieldcatalog-fieldname     = 'MAKTX'.
  fieldcatalog-tabname       = 'GT_FINAL'.
  fieldcatalog-ref_tabname   = 'MAKT'.
  fieldcatalog-ref_fieldname = 'MAKTX'.
  fieldcatalog-col_pos       = cnt.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR  fieldcatalog.
  ADD 1 TO cnt.
  fieldcatalog-fieldname     = 'MERGNO'.
  fieldcatalog-tabname       = 'GT_FINAL'.
  fieldcatalog-ref_tabname   = 'ZPP_PACK'.
  fieldcatalog-ref_fieldname = 'MERGNO'.
  fieldcatalog-col_pos       = cnt.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR  fieldcatalog.
  ADD 1 TO cnt.
  fieldcatalog-fieldname    = 'GRADE'.
  fieldcatalog-tabname      = 'GT_FINAL'.
  fieldcatalog-seltext_m    = 'Grade'.
  fieldcatalog-col_pos      = cnt.
  fieldcatalog-ddictxt      = 'M'.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR  fieldcatalog.
  ADD 1 TO cnt.
  fieldcatalog-fieldname    = 'PSIZE'.
  fieldcatalog-tabname      = 'GT_FINAL'.
  fieldcatalog-seltext_m    = 'Size'.
  fieldcatalog-col_pos      = cnt.
  fieldcatalog-ddictxt      = 'M'.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR  fieldcatalog.
  ADD 1 TO cnt.
  fieldcatalog-fieldname    = 'PTYPE'.
  fieldcatalog-tabname      = 'GT_FINAL'.
  fieldcatalog-seltext_m    = 'Packing Type'.
  fieldcatalog-col_pos      = cnt.
  fieldcatalog-ddictxt      = 'M'.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR  fieldcatalog.
  ADD 1 TO cnt.
  fieldcatalog-fieldname     = 'PDATE'.
  fieldcatalog-tabname       = 'GT_FINAL'.
  fieldcatalog-seltext_m     = 'Prod. Date'.
  fieldcatalog-ref_tabname   = 'ZPP_PACK'.
  fieldcatalog-ref_fieldname = 'PDATE'.
  fieldcatalog-col_pos       = cnt.
  fieldcatalog-ddictxt       = 'M'.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR  fieldcatalog.
  ADD 1 TO cnt.
  fieldcatalog-fieldname     = 'SPOOLNO'.
  fieldcatalog-tabname       = 'GT_FINAL'.
  fieldcatalog-seltext_m     = 'No. of Spool'.
  fieldcatalog-ref_tabname   = 'ZPP_PACK'.
  fieldcatalog-ref_fieldname = 'SPOOLNO'.
  fieldcatalog-col_pos       = cnt.
  fieldcatalog-ddictxt       = 'M'.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR  fieldcatalog.
  ADD 1 TO cnt.
  fieldcatalog-fieldname     = 'NETWT'.
  fieldcatalog-tabname       = 'GT_FINAL'.
  fieldcatalog-ref_tabname   = 'ZPP_PACK'.
  fieldcatalog-ref_fieldname = 'NETWT'.
  fieldcatalog-ddictxt       = 'M'.
  fieldcatalog-seltext_m     = 'Net Weight'.
  fieldcatalog-col_pos       = cnt.
  fieldcatalog-do_sum        = 'X'.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR  fieldcatalog.
  ADD 1 TO cnt.
  fieldcatalog-fieldname     = 'GROSSWT'.
  fieldcatalog-tabname       = 'GT_FINAL'.
  fieldcatalog-seltext_m     = 'Gross Weight'.
  fieldcatalog-ref_tabname   = 'ZPP_PACK'.
  fieldcatalog-ref_fieldname = 'GROSSWT'.
  fieldcatalog-ddictxt       = 'M'.
  fieldcatalog-col_pos       = cnt.
  fieldcatalog-do_sum        = 'X'.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR  fieldcatalog.
  ADD 1 TO cnt.
  fieldcatalog-fieldname     = 'TAREWT'.
  fieldcatalog-tabname       = 'GT_FINAL'.
  fieldcatalog-seltext_m     = 'Tare Weight'.
  fieldcatalog-ref_tabname   = 'ZPP_PACK'.
  fieldcatalog-ref_fieldname = 'TAREWT'.
  fieldcatalog-ddictxt       = 'M'.
  fieldcatalog-col_pos       = cnt.
  fieldcatalog-do_sum        = 'X'.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR  fieldcatalog.
  ADD 1 TO cnt.
  fieldcatalog-fieldname     = 'LOCEXP'.
  fieldcatalog-tabname       = 'GT_FINAL'.
  fieldcatalog-seltext_m     = 'Loc/Exp'.
  fieldcatalog-ref_tabname   = 'LOCEXP'.
  fieldcatalog-ref_fieldname = 'ZPP_PACK'.
  fieldcatalog-ddictxt       = 'M'.
  fieldcatalog-col_pos       = cnt.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR  fieldcatalog.
  ADD 1 TO cnt.
  fieldcatalog-fieldname     = 'EXIDV2'.
  fieldcatalog-tabname       = 'GT_FINAL'.
  fieldcatalog-seltext_m     = 'Old Box No.'.
  fieldcatalog-ref_tabname   = 'VEKP'.
  fieldcatalog-ref_fieldname = 'EXIDV2'.
  fieldcatalog-ddictxt       = 'M'.
  fieldcatalog-col_pos       = cnt.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR  fieldcatalog.
  ADD 1 TO cnt.
  fieldcatalog-fieldname     = 'REMARKS'.
  fieldcatalog-tabname       = 'GT_FINAL'.
  fieldcatalog-seltext_m     = 'Remarks'.
  fieldcatalog-ddictxt       = 'M'.
  fieldcatalog-col_pos       = cnt.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR  fieldcatalog.
ENDFORM.                    " BUILD_FIELDCATALOG
*&---------------------------------------------------------------------*
*&      Form  BUILD_LAYOUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM build_layout .
  gd_layout-colwidth_optimize = 'X'.
  gd_layout-zebra             = 'X'.
*    gs_sort-fieldname = 'VGBEL'.
*    gs_sort-tabname   = 'GT_FINAL'.
*    APPEND gs_sort TO gt_sort.
ENDFORM.                    " BUILD_LAYOUT
*&---------------------------------------------------------------------*
*&      Form  set_pf_status
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM set_pf_status USING rt_extab TYPE slis_t_extab.
  SET PF-STATUS 'PF_STATUS'.
ENDFORM.                    "set_pf_status
*&---------------------------------------------------------------------*
*&      Form  DISPLAY_ALV_REPORT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM display_alv_report .
  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
    EXPORTING
      i_callback_program       = sy-repid
      i_callback_pf_status_set = 'SET_PF_STATUS'
      i_callback_user_command  = 'USER_COMMAND'
      is_layout                = gd_layout
      it_fieldcat              = fieldcatalog[]
      i_default                = 'X'
      i_save                   = 'A'
    TABLES
      t_outtab                 = gt_final[].
  IF sy-subrc <> 0.
* Implement suitable error handling here
  ENDIF.
ENDFORM.                    " DISPLAY_ALV_REPORT
*&---------------------------------------------------------------------*
*&      Form  user_command
*&---------------------------------------------------------------------*
FORM user_command  USING r_ucomm LIKE sy-ucomm
                                   rs_selfield TYPE slis_selfield.
  CASE r_ucomm.
    WHEN 'CREATE'.
      CALL FUNCTION 'GET_GLOBALS_FROM_SLVC_FULLSCR'
        IMPORTING
          e_grid = alv_grid.
      CALL METHOD alv_grid->check_changed_data.
      CALL METHOD alv_grid->refresh_table_display.
      BREAK abap_dev.
      PERFORM post_box.
      PERFORM update_list.
      CALL FUNCTION 'GET_GLOBALS_FROM_SLVC_FULLSCR'
        IMPORTING
          e_grid = alv_grid.
      CALL METHOD alv_grid->check_changed_data.
      CALL METHOD alv_grid->refresh_table_display.
    WHEN '&ALL'.
      CALL FUNCTION 'GET_GLOBALS_FROM_SLVC_FULLSCR'
        IMPORTING
          e_grid = alv_grid.
      LOOP AT gt_final INTO gw_final.
        gw_final-chk = 'X'.
        MODIFY gt_final FROM gw_final.
      ENDLOOP.
      CALL METHOD alv_grid->check_changed_data.
      CALL METHOD alv_grid->refresh_table_display.
      CALL FUNCTION 'GET_GLOBALS_FROM_SLVC_FULLSCR'
        IMPORTING
          e_grid = alv_grid.
      CALL METHOD alv_grid->check_changed_data.
      CALL METHOD alv_grid->refresh_table_display.
    WHEN '&SAL'.
      CALL FUNCTION 'GET_GLOBALS_FROM_SLVC_FULLSCR'
        IMPORTING
          e_grid = alv_grid.
      CALL METHOD alv_grid->check_changed_data.
      CALL METHOD alv_grid->refresh_table_display.
      LOOP AT gt_final INTO gw_final.
        gw_final-chk = ''.
        MODIFY gt_final FROM gw_final.
      ENDLOOP.
      CALL FUNCTION 'GET_GLOBALS_FROM_SLVC_FULLSCR'
        IMPORTING
          e_grid = alv_grid.
      CALL METHOD alv_grid->check_changed_data.
      CALL METHOD alv_grid->refresh_table_display.
  ENDCASE.
ENDFORM.                    "user_command
*&---------------------------------------------------------------------*
*&      Form  PROCESS_DATA
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM process_data.
  IF gt_data[] IS NOT INITIAL.
    SELECT a~vkorg a~vtweg a~spart a~auart a~vgbel
        b~vbeln b~posnr b~matnr b~charg
        b~kwmeng b~vrkme b~werks b~vgpos
        b~lgort b~zzlrno b~zzsize b~zzsiz1 b~zzsiz2
        b~zzgrade b~zzgrad1 b~zzgrad2
        INTO CORRESPONDING FIELDS OF TABLE gt_vbak
        FROM vbak AS a
        INNER JOIN vbap AS b
        ON  a~vbeln = b~vbeln
        FOR ALL ENTRIES IN gt_data
        WHERE b~vbeln EQ gt_data-vbeln.
*   Read every item of the order, not only the one on the payload
*   (04.09.2026). The Scan Suite copies each box's item from the
*   download list into PickToDetails-Item_No, but the download report
*   never fills that item in - so it arrives here blank, GT_DATA-POSNR is
*   empty, and the item is recovered from the box's own ZPP_PACK row in
*   the loop below. GT_VBAK must therefore hold ALL of the order's items
*   so the recovered item can be validated; restricting it to the (empty)
*   payload item is what made every box read as "Invalid Sales Order".
    SELECT * FROM zpp_pack INTO TABLE gt_zpppack
         FOR ALL ENTRIES IN gt_data
         WHERE boxno  EQ gt_data-boxno AND
               matnr  EQ gt_data-matnr AND
               mergno EQ gt_data-mergno AND
               werks  EQ gt_data-werks AND
               psize  EQ gt_data-psize AND
               ptype  EQ gt_data-ptype. " AND
    "vbeln  eq gt_data-vbeln and
    "posnr  eq gt_Data-posnr.
  ENDIF.
  LOOP AT gt_data INTO gw_data.

*   RECOVER THE ORDER ITEM WHEN THE APP DID NOT SEND ONE (04.09.2026)
*   PickToDetails-Item_No is copied by the Scan Suite from the download
*   box list (HU_Details-Itemno). The download report does not populate
*   that item, so it arrives here blank and every box failed the
*   sales-order-item check below with "Invalid Sales Order" - even for
*   orders whose boxes list correctly. The box's own ZPP_PACK row carries
*   the item it was produced against (the make-to-order stamp), and
*   GT_ZPPPACK is already read by box number above; use it to fill the
*   missing item. Only fills a BLANK item, so once the app sends the item
*   itself this becomes a no-op. GT_VBAK was widened to the whole order
*   above so the recovered item resolves.
    IF gw_data-posnr IS INITIAL.
*     (a) Make-to-order: the box's own ZPP_PACK row carries the item.
      READ TABLE gt_zpppack INTO gw_zpppack WITH KEY boxno = gw_data-boxno.
      IF sy-subrc EQ 0 AND gw_zpppack-posnr IS NOT INITIAL.
        gw_data-posnr = gw_zpppack-posnr.
      ELSE.
*       (b) Free stock: the box is not stamped with an item, so take the
*       order item that carries the box's material. GT_VBAK now holds
*       every item of the order.
        READ TABLE gt_vbak INTO gw_vbak
             WITH KEY vbeln = gw_data-vbeln
                      matnr = gw_data-matnr.
        IF sy-subrc EQ 0.
          gw_data-posnr = gw_vbak-posnr.
        ENDIF.
        CLEAR gw_vbak.
      ENDIF.
      CLEAR gw_zpppack.
    ENDIF.

    MOVE-CORRESPONDING gw_data TO gw_final.
    MOVE gw_data-pdate TO gw_final-pdate.
    SELECT pklst FROM zpp_pack
      INTO TABLE it_zpppack
      WHERE vbeln EQ gw_data-vbeln
        AND posnr EQ gw_data-posnr.
*      check: not it_zpppack[] is initial.
    SORT it_zpppack BY pklst.
    DELETE ADJACENT DUPLICATES FROM it_zpppack
                                  COMPARING pklst.
    DESCRIBE TABLE it_zpppack LINES count.
    SORT it_zpppack BY pklst DESCENDING.
    CALL FUNCTION 'CONVERSION_EXIT_ALPHA_OUTPUT'
      EXPORTING
        input  = gw_data-posnr
      IMPORTING
        output = v_posnr.
    CONCATENATE v_posnr v_buzei INTO v_buzei.
    IF count IS INITIAL.
      ADD 1 TO v_buzei.
    ELSE.
      READ TABLE it_zpppack INTO wa_zpppack INDEX 1.
      count  = wa_zpppack-pklst.
      ADD 1 TO count.
      v_buzei = count.
*      ADD count TO v_buzei.
    ENDIF.
    MOVE v_buzei TO gw_final-pklst.
    "read table gt_zpppack into gw_zpppack with key boxno = gw_data-boxno.
*      if sy-subrc eq 0.
*        move gw_zpppack-gjahr to gw_final-gjahr.
*       endif.
    READ TABLE gt_vbak INTO gw_vbak WITH KEY vbeln = gw_data-vbeln
                                             posnr = gw_data-posnr.
    IF sy-subrc NE 0.                                                             "Invalid Sales Order
      gw_final-remarks = 'Invalid Sales Order'.
      gw_final-iconid = '@0A@'.
      v_error = 'X'.
    ENDIF.
    IF v_error  NE 'X'.
      IF gw_vbak-abgru IS NOT INITIAL.
        CLEAR:mess.                                                                "Sales Order Closed
        CONCATENATE 'Sales Order' gw_vbak-vbeln 'already closed'
                  INTO mess SEPARATED BY space.
        gw_final-remarks = mess.
        gw_final-iconid = '@0A@'.
      ELSE.
        CLEAR v_abgru.
        SELECT SINGLE abgru INTO v_abgru                                            "Contract Closed
            FROM vbap
            WHERE vbeln EQ gw_vbak-vgbel AND
                   posnr EQ gw_vbak-vgpos.
        IF v_abgru IS NOT INITIAL.
          CONCATENATE 'Contract' gw_vbak-vgbel gw_vbak-vgpos 'already closed'
                            INTO mess SEPARATED BY space.
          gw_final-remarks = mess.
          gw_final-iconid = '@0A@'.
        ENDIF.
      ENDIF.
    ENDIF.
    IF gw_final-remarks IS INITIAL.
      READ TABLE gt_zpppack INTO gw_zpppack WITH KEY boxno = gw_data-boxno.
*     A box is genuinely "already packed" only once it carries a PACKING
*     LIST number (PKLST) - that is what POST_BOX writes when a box is
*     packed. On make-to-order lines the carton already carries its sales
*     order (VBELN/POSNR) from production, before it is ever packed, so
*     testing VBELN here rejected every such box with "Box No ... is not
*     assigned" though it was free to pack. Test PKLST for the re-pack
*     guard; test VBELN only to catch a box pre-stamped for a DIFFERENT
*     order/item. (04.09.2026)
      IF gw_zpppack-pklst IS NOT INITIAL.
        CONCATENATE 'Box already assigned to ' gw_zpppack-vbeln gw_zpppack-posnr ' Packing List' gw_zpppack-pklst '.'
                                 INTO mess SEPARATED BY space.
        gw_final-remarks = mess.
        gw_final-iconid = '@0A@'.
      ELSEIF gw_zpppack-vbeln IS NOT INITIAL AND
             ( gw_zpppack-vbeln NE gw_data-vbeln OR
               gw_zpppack-posnr NE gw_data-posnr ).
        CONCATENATE 'Box belongs to sales order' gw_zpppack-vbeln gw_zpppack-posnr '.'
                                 INTO mess SEPARATED BY space.
        gw_final-remarks = mess.
        gw_final-iconid = '@0A@'.
      ENDIF.
    ENDIF.
    IF gw_final-remarks IS INITIAL.
      gw_final-iconid = '@08@'.                      "Green
    ELSE.
      gw_final-pklst = ''.
    ENDIF.
    APPEND gw_final TO gt_final.
    CLEAR: gw_final, count, v_posnr, v_buzei, gw_zpppack, gw_vbak.
  ENDLOOP.
ENDFORM.                    " PROCESS_DATA
*&---------------------------------------------------------------------*
*&      Form  POST_BOX
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM post_box.
* ----------------------------------------------------------------------
* QUANTITY RANGE CHECK - two additions of 07.09.2026, both local to this
* FORM and both read by the Scan Suite's Packing List screen, which
* applies the same two rules box by box before the operator ever gets
* here (index.html, fitCheck / capFor).
*
* 1. ROLLS ARE COUNTED, NOT WEIGHED. Mango knitted fabric (plants 8001 /
*    8003) is sold in VBAP-VRKME = ROL with a 1:1 conversion to KG, so
*    KWMENG is a roll count while every ZPP_PACK box carries its real net
*    weight (15-60 KG on one order). Summing kilos against 26 ROL refused
*    the second roll. For a piece unit (ROL, PC, PCE, ST, EA) every box
*    counts one, on both sides of the comparison; weight stays the
*    measure for everything else.
*
* 2. SOCHG HEADROOM. A Scan Suite user holding the Change Sales Order
*    screen (SOCHG) may pack a whole lot onto an item, up to 10% over the
*    order quantity - the tolerance becomes the larger of ZSDTOL's upper
*    tolerance and 10% of KWMENG (10% of ZMENG on the contract branch,
*    which sales org 2002 already had). ZCL_PICKUPLOAD_DPC_EXT puts the
*    flag in ABAP memory ('ZSOL_SOCHG') before the SUBMIT and frees it
*    after; anything else that runs this report finds no flag and gets
*    the tolerance as before.
* ----------------------------------------------------------------------
  DATA: lv_sochg TYPE c LENGTH 1,
        lv_piece TYPE c LENGTH 1,
        lv_tol   TYPE zpp_pack-netwt,
        lv_pct   TYPE zpp_pack-netwt.

  IMPORT sochg = lv_sochg FROM MEMORY ID 'ZSOL_SOCHG'.
  IF sy-subrc <> 0.
    CLEAR lv_sochg.
  ENDIF.

  gt_final1[] = gt_final[].
  IF p_chk IS INITIAL.
    DELETE gt_final1[] WHERE chk NE 'X'.
  ENDIF.
  DELETE ADJACENT DUPLICATES FROM gt_final1 COMPARING vbeln posnr.
  LOOP AT gt_final1 INTO gw_final1.
    IF gw_final1-remarks IS NOT INITIAL.
*     Surface the ACTUAL reason (invalid order, order/contract closed,
*     box belongs to another order, or already packed) instead of the
*     generic - and here misleading - "is not assigned". (04.09.2026)
      CONCATENATE 'Box No' gw_final1-boxno ':' gw_final1-remarks
                  INTO v_msgtxt1 SEPARATED BY space.
      MESSAGE e000(8i) WITH v_msgtxt1.
    ENDIF.
    CHECK: gw_final1-remarks IS INITIAL.
    CLEAR: wa_zpp_pack, wa_zsdtol, gw_vbak, gw_final.
    CLEAR: sum_netwt,up_netwt,lef_netwt.
    READ TABLE gt_vbak INTO gw_vbak WITH KEY vbeln = gw_final1-vbeln
                                             posnr = gw_final1-posnr.
*   Piece unit on the order item: count boxes (rule 1 above).
    CLEAR lv_piece.
    IF gw_vbak-vrkme = 'ROL' OR gw_vbak-vrkme = 'PC' OR gw_vbak-vrkme = 'PCE'
       OR gw_vbak-vrkme = 'ST' OR gw_vbak-vrkme = 'EA'.
      lv_piece = 'X'.
    ENDIF.
    SELECT SINGLE * FROM zsdtol
      INTO wa_zsdtol
      WHERE vkorg EQ gw_vbak-vkorg AND
            vtweg EQ gw_vbak-vtweg AND
            spart EQ gw_vbak-spart.
    SELECT * FROM zpp_pack
             INTO TABLE it_zpp_pack
             WHERE vbeln EQ gw_vbak-vbeln AND
                   posnr EQ gw_vbak-posnr.
    LOOP AT it_zpp_pack INTO wa_zpp_pack.
*     Count only boxes that are actually packed (carry a packing list) as
*     already-packed qty. A make-to-order box carries VBELN from
*     production before it is packed (PKLST still blank); counting those
*     made the tolerance treat the order as already fully packed and
*     rejected the pack with "outside range". No-op for normal stock,
*     where VBELN and PKLST are set together at packing. (04.09.2026)
      CHECK wa_zpp_pack-pklst IS NOT INITIAL.
      IF lv_piece = 'X'.
        ADD 1 TO sum_netwt.
      ELSE.
        ADD wa_zpp_pack-netwt TO sum_netwt.
      ENDIF.
    ENDLOOP.
    CLEAR: gw_final1-lwtol,gw_final1-uptol,lef_netwt.
*   Upper tolerance: ZSDTOL, or 10% of the order quantity for a SOCHG
*   user when that is more (rule 2 above).
    lv_tol = wa_zsdtol-uptol.
    IF lv_sochg = 'X'.
      lv_pct = gw_vbak-kwmeng * '0.1'.
      IF lv_pct > lv_tol.
        lv_tol = lv_pct.
      ENDIF.
    ENDIF.
    gw_final1-uptol = lv_tol         +                                          " Upper Tolerance
                      gw_vbak-kwmeng -                                          " Sales order qty
                      sum_netwt.                                                " Packed qty
    LOOP AT gt_final INTO gw_final WHERE vbeln = gw_final1-vbeln
                                     AND posnr = gw_final1-posnr
                                     AND chk = 'X'.
      IF lv_piece = 'X'.
        ADD 1 TO up_netwt.
      ELSE.
        ADD gw_final-netwt TO up_netwt.
      ENDIF.
    ENDLOOP.
    IF up_netwt NOT BETWEEN gw_final1-lwtol AND gw_final1-uptol.
      lef_netwt = up_netwt - gw_final1-uptol.
      MOVE lef_netwt TO lef_str.
      CONCATENATE 'Packing List' gw_final-pklst 'is outside range by qty'
                  INTO v_msgtxt1 SEPARATED BY space.
      CONCATENATE lef_str gw_vbak-vrkme 'against SO'
                  INTO v_msgtxt2 SEPARATED BY space.
      MESSAGE e000(8i) WITH v_msgtxt1 v_msgtxt2.
    ELSE.
      CLEAR: gw_final1-lwtol,gw_final1-uptol,sum_netwt,wa_vbfa,lef_netwt.
      SELECT SINGLE * FROM vbfa
                      INTO wa_vbfa
                      WHERE vbeln EQ gw_final1-vbeln AND
                            posnn EQ gw_final1-posnr.
      IF wa_vbfa-vbtyp_v EQ 'G'.                                                      " For contract only
        SELECT SINGLE vbeln
                      posnr
                      zmeng
                      FROM vbap
                      INTO wa_vbakc
                      WHERE vbeln EQ gw_vbak-vgbel AND
                            posnr EQ gw_vbak-vgpos.
        IF wa_vbakc-vbeln IS NOT INITIAL.
          SELECT  vbeln
                  posnr
                  zmeng
                  FROM vbap
                  INTO CORRESPONDING FIELDS OF TABLE it_vbakc
                  WHERE vgbel EQ wa_vbakc-vbeln AND
                        vgpos EQ wa_vbakc-posnr.
          SELECT * FROM zpp_pack
                 INTO TABLE it_zpp_pack
                 FOR ALL ENTRIES IN it_vbakc
                 WHERE vbeln EQ it_vbakc-vbeln AND
                       posnr EQ it_vbakc-posnr.
          LOOP AT it_zpp_pack INTO wa_zpp_pack.
            CHECK wa_zpp_pack-pklst IS NOT INITIAL.   " packed qty only - see note in main loop above
            IF lv_piece = 'X'.
              ADD 1 TO sum_netwt.                     " rolls are counted - rule 1 above
            ELSE.
              ADD wa_zpp_pack-netwt TO sum_netwt.
            ENDIF.
          ENDLOOP.
        ENDIF.
        BREAK abap_dev.
*       Sales org 2002 has always had 10% of the contract quantity here;
*       a SOCHG user gets the same, whichever org, when it is more than
*       ZSDTOL (rule 2 above).
        lv_tol = wa_zsdtol-uptol.
        lv_pct = wa_vbakc-zmeng * '0.1'.
        IF gw_vbak-vkorg = '2002'.
          lv_tol = lv_pct.
        ELSEIF lv_sochg = 'X' AND lv_pct > lv_tol.
          lv_tol = lv_pct.
        ENDIF.
        gw_final1-uptol = lv_tol         +                                  " Upper Tolerance
                          wa_vbakc-zmeng -                                  " Contract qty
                          sum_netwt.                                        " Packed qty
        IF up_netwt NOT BETWEEN gw_final1-lwtol AND gw_final1-uptol.
          lef_netwt = up_netwt - gw_final1-uptol.
          MOVE lef_netwt TO lef_str.
          CONCATENATE 'Packing List' gw_final1-pklst 'is outside range by qty'
                  INTO v_msgtxt1 SEPARATED BY space.
          CONCATENATE lef_str gw_vbak-vrkme 'against Contract'
                      INTO v_msgtxt2 SEPARATED BY space.
          MESSAGE e000(8i) WITH v_msgtxt1 v_msgtxt2.
        ENDIF.
      ENDIF.
    ENDIF.
    "====================================== for packing list overwrite =============================
  IF p_chk IS NOT INITIAL.
    SELECT boxno, vbeln, posnr, pklst FROM zpp_pack INTO TABLE @DATA(pk_lst) FOR ALL ENTRIES IN @gt_final
         WHERE boxno = @gt_final-boxno.
    IF sy-subrc = 0.
      LOOP AT gt_final ASSIGNING FIELD-SYMBOL(<fs_final>) WHERE chk EQ 'X'
                                       AND vbeln EQ gw_final1-vbeln
                                       AND posnr EQ gw_final1-posnr.
        READ TABLE pk_lst INTO DATA(wa_lst) WITH KEY boxno = <fs_final>-boxno.
        IF sy-subrc = 0 AND wa_lst-pklst IS NOT INITIAL.
          CLEAR: <fs_final>.
        ENDIF.
      ENDLOOP.
      DELETE gt_final WHERE boxno IS INITIAL.
    ENDIF.
  ENDIF.
  "====================================== for packing list overwrite =============================
  LOOP AT gt_final INTO gw_final WHERE chk EQ 'X'
                                   AND vbeln EQ gw_final1-vbeln
                                   AND posnr EQ gw_final1-posnr.
    UPDATE zpp_pack SET vbeln = gw_final-vbeln
                        posnr = gw_final-posnr
                        pklst = gw_final-pklst
                        pldate = sy-datum
          WHERE boxno = gw_final-boxno.
*              AND gjahr = gw_final-gjahr.
    DELETE gt_final WHERE boxno = gw_final-boxno.
    IF sy-subrc NE 0.
      v_error = 'X'.
    ENDIF.
  ENDLOOP.
  IF v_error = 'X'.
    MESSAGE i002(sy) WITH 'Updation Error, try again'.
  ELSE.
    COMMIT WORK.
    MESSAGE s002(sy) WITH 'Packing List created'.
*      v_save = 'X'.
  ENDIF.
  CLEAR: sum_netwt,wa_zsdtol,up_netwt.
  CLEAR: wa_zpp_pack, wa_zsdtol, gw_vbak, gw_final.
ENDLOOP.
ENDFORM.                    " POST_BOX
*&---------------------------------------------------------------------*
*&      Form  UPDATE_LIST
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM update_list.
  LOOP AT gt_final INTO gw_final.
    CHECK: gw_final-remarks IS INITIAL.
    CLEAR:count, v_posnr, v_buzei.
    SELECT pklst FROM zpp_pack
      INTO TABLE it_zpppack
      WHERE vbeln EQ gw_final-vbeln
        AND posnr EQ gw_final-posnr.
*      check: not it_zpppack[] is initial.
      SORT it_zpppack BY pklst.
      DELETE ADJACENT DUPLICATES FROM it_zpppack
                                    COMPARING pklst.
      DESCRIBE TABLE it_zpppack LINES count.
      SORT it_zpppack BY pklst DESCENDING.
      CALL FUNCTION 'CONVERSION_EXIT_ALPHA_OUTPUT'
        EXPORTING
          input  = gw_data-posnr
        IMPORTING
          output = v_posnr.
      CONCATENATE v_posnr v_buzei INTO v_buzei.
      IF count IS INITIAL.
        ADD 1 TO v_buzei.
      ELSE.
        READ TABLE it_zpppack INTO wa_zpppack INDEX 1.
        count = wa_zpppack-pklst.
        ADD 1 TO count.
        v_buzei = count.
*      ADD count TO v_buzei.
      ENDIF.
      MOVE v_buzei TO gw_final-pklst.
      MODIFY gt_final FROM gw_final.
    ENDLOOP.
ENDFORM.                    " UPDATE_LIST
