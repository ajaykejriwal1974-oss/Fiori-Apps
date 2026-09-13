*&---------------------------------------------------------------------*
*&  Include           ZRPT_SALES_001_FR
*&---------------------------------------------------------------------*

*&---------------------------------------------------------------------*
*&      Form  F4_FOR_VARIANT
*&---------------------------------------------------------------------*
FORM f4_for_variant .
  CALL FUNCTION 'REUSE_ALV_VARIANT_F4'
    EXPORTING
      is_variant = g_variant
      i_save     = g_save
    IMPORTING
      e_exit     = g_exit
      es_variant = gx_variant
    EXCEPTIONS
      not_found  = 2.
  IF sy-subrc = 2.
    MESSAGE ID sy-msgid TYPE 'S'      NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ELSE.
    IF g_exit = space.
      p_vari = gx_variant-variant.
    ENDIF.
  ENDIF.
ENDFORM.                    " F4_FOR_VARIANT

*&---------------------------------------------------------------------*
*&      Form  DATA_RETRIEVAL
*&---------------------------------------------------------------------*
FORM data_retrieval .

  CLEAR: v_flag,
         wa_sorg, it_sorg[],
         wa_vkorg, it_vkorg[].

  SELECT vkorg FROM tvko INTO TABLE it_vkorg
    WHERE vkorg IN s_vkorg.
  CHECK: sy-subrc EQ 0.

  LOOP AT it_vkorg INTO wa_vkorg.

    AUTHORITY-CHECK OBJECT 'V_VBRK_VKO'
             ID 'VKORG' FIELD wa_vkorg-vkorg
             ID 'ACTVT' FIELD '03'.

    IF sy-subrc EQ 0.
      wa_sorg-sign    = 'I'.
      wa_sorg-option  = 'EQ'.
      wa_sorg-low     = wa_vkorg-vkorg.
      APPEND wa_sorg TO it_sorg.
    ELSE.
      v_flag = 'X'.
    ENDIF.

  ENDLOOP.

  IF v_flag = 'X'.
    MESSAGE i499(sy) WITH 'Output restricted as per authorization'.
  ENDIF.

  IF it_sorg[] IS INITIAL.
    MESSAGE i499(sy) WITH 'No output for selection'.
  ENDIF.

  CHECK: NOT it_sorg[] IS INITIAL.

  SELECT * FROM vbak
           INTO TABLE gt_vbak
           WHERE vbeln IN s_so    AND
                 audat IN s_audat AND
                 vkorg IN it_sorg AND
                 vtweg IN s_vtweg AND
                 spart IN s_spart AND
                 vbtyp EQ 'C'
  %_HINTS ORACLE 'INDEX ("VBAK" "VBAK~ZP1")'.            "Order

  IF gt_vbak[] IS NOT INITIAL.

    SELECT * FROM vbak
             INTO TABLE gt_vbakc
             FOR ALL ENTRIES IN gt_vbak
             WHERE vbeln EQ gt_vbak-vgbel AND
                   trvog EQ '4'.        "Contract

    IF gt_vbakc[] IS NOT INITIAL.
      SELECT * FROM vbap
               INTO TABLE gt_vbapc
               FOR ALL ENTRIES IN gt_vbakc
               WHERE vbeln EQ gt_vbakc-vbeln.
    ENDIF.

    SELECT * FROM vbap
             INTO TABLE gt_vbap
             FOR ALL ENTRIES IN gt_vbak
             WHERE vbeln EQ gt_vbak-vbeln AND
                   matnr IN s_matnr.

    SELECT knumv
           kposn
           kschl
           kbetr
FROM prcd_elements
" FROM KONV auto changed
INTO TABLE gt_prcd_elements
" INTO TABLE GT_KONV auto changed
                 FOR ALL ENTRIES IN gt_vbak
                 WHERE knumv EQ gt_vbak-knumv.

**    SELECT * FROM vbpa                                "commented by mv22062015.
**             INTO TABLE gt_vbpa
**             FOR ALL ENTRIES IN gt_vbak
**             WHERE vbeln EQ gt_vbak-vbeln.


    SELECT vbeln                                       "added by mv22062015.
           parvw
           kunnr
           INTO TABLE gt_vbpa
           FROM vbpa
           FOR ALL ENTRIES IN gt_vbak
           WHERE vbeln EQ gt_vbak-vbeln.

    IF gt_vbpa[] IS NOT INITIAL.
      SELECT * FROM kna1
               INTO TABLE gt_kna1
               FOR ALL ENTRIES IN gt_vbpa
               WHERE kunnr EQ gt_vbpa-kunnr.

      IF gt_kna1[] IS NOT INITIAL.
        SELECT * FROM kna1
        " SELECT * FROM J_1IMOCUST auto changed
        INTO TABLE gt_kna1
        " INTO TABLE GT_J_1IMOCUST auto changed
                         FOR ALL ENTRIES IN gt_kna1
                         WHERE kunnr EQ gt_kna1-kunnr.

        SELECT * FROM adrc
                 INTO TABLE gt_adrc
                 FOR ALL ENTRIES IN gt_kna1
                 WHERE addrnumber EQ gt_kna1-adrnr.
      ENDIF.
    ENDIF.

    IF gt_vbap[] IS NOT INITIAL.
*      SELECT * FROM lips
*               INTO TABLE gt_lips
*               FOR ALL ENTRIES IN gt_vbap
*               WHERE vgbel EQ gt_vbap-vbeln AND
*                     vgpos EQ gt_vbap-posnr
*        %_HINTS ORACLE 'INDEX ("LIPS" "LIPS~Z1")'.
      SELECT vbeln                                     "added by mv.
             posnr
             lfimg
             vgbel
             vgpos FROM lips
                   INTO TABLE gt_lips
                   FOR ALL ENTRIES IN gt_vbap
                   WHERE vgbel EQ gt_vbap-vbeln AND
                         vgpos EQ gt_vbap-posnr
        %_HINTS ORACLE 'INDEX ("LIPS" "LIPS~Z1")'.

      IF gt_lips[] IS NOT INITIAL.

        SELECT * FROM likp
                 INTO TABLE gt_likp
                 FOR ALL ENTRIES IN gt_lips
                 WHERE vbeln EQ gt_lips-vbeln.

        IF gt_likp[] IS NOT INITIAL.
          SELECT * FROM tvlkt
                   INTO TABLE gt_tvlkt
                   FOR ALL ENTRIES IN gt_likp
                   WHERE lfart EQ gt_likp-lfart AND
                         spras EQ 'EN'.
        ENDIF.
        SELECT * FROM vbrp
                 INTO TABLE gt_vbrp
                 FOR ALL ENTRIES IN gt_lips
                 WHERE vgbel EQ gt_lips-vbeln AND
                       vgpos EQ gt_lips-posnr
       %_HINTS ORACLE 'INDEX ("VBRP" "VBRP~ZD2")'.

        IF gt_vbrp[] IS NOT INITIAL.
          SELECT * FROM vbrk
                   INTO TABLE gt_vbrk
                   FOR ALL ENTRIES IN gt_vbrp
                   WHERE vbeln EQ gt_vbrp-vbeln.
          IF gt_vbrk[] IS NOT INITIAL.
            SELECT * FROM t151t
                     INTO TABLE gt_t151t
                     FOR ALL ENTRIES IN gt_vbrk
                     WHERE kdgrp EQ gt_vbrk-kdgrp AND
                           spras EQ 'EN'.
            SELECT * FROM t189t
                   INTO TABLE gt_t189t
                   FOR ALL ENTRIES IN gt_vbrk
                   WHERE pltyp EQ gt_vbrk-pltyp AND
                         spras EQ 'EN'.
          ENDIF.
        ENDIF.
      ENDIF.

      SELECT * FROM zpp_grade
               INTO TABLE gt_grade
               FOR ALL ENTRIES IN gt_vbap
               WHERE gcode EQ gt_vbap-zzgrade.

      SELECT * FROM mchb
               INTO TABLE gt_mchb
               FOR ALL ENTRIES IN gt_vbap
               WHERE matnr EQ gt_vbap-matnr AND
                     werks EQ gt_vbap-werks AND
                     lgort EQ gt_vbap-lgort AND
                     charg EQ gt_vbap-charg
      %_HINTS ORACLE 'INDEX ("MCHB" "MCHB~Z1")'.

      SELECT * FROM vbup
               INTO TABLE gt_vbup
               FOR ALL ENTRIES IN gt_vbap
               WHERE vbeln EQ gt_vbap-vbeln AND
                     posnr EQ gt_vbap-posnr.

      SELECT * FROM vbup
               APPENDING TABLE gt_vbup
               FOR ALL ENTRIES IN gt_vbakc
               WHERE vbeln EQ gt_vbakc-vbeln.

      SELECT * FROM zsdtol
               INTO TABLE gt_sdtol.

      SELECT * FROM vbkd
               INTO TABLE gt_vbkd
               FOR ALL ENTRIES IN gt_vbap
               WHERE vbeln EQ gt_vbap-vbeln." AND
*                     posnr EQ gt_vbap-posnr.

    ENDIF.
  ENDIF.
*  ENDIF.

ENDFORM.                    " DATA_RETRIEVAL

*&---------------------------------------------------------------------*
*&      Form  BUILD_FIELDCATALOG
*&---------------------------------------------------------------------*
FORM build_fieldcatalog .

  fieldcatalog-fieldname      = 'VGBEL'.
  fieldcatalog-tabname        = 'GT_FINAL'.
  fieldcatalog-key            = 'X'.
  fieldcatalog-seltext_m      = TEXT-003.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR fieldcatalog.

  fieldcatalog-fieldname      = 'VGPOS'.
  fieldcatalog-tabname        = 'GT_FINAL'.
  fieldcatalog-key            = 'X'.
  fieldcatalog-seltext_m      = TEXT-021.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR fieldcatalog.

  fieldcatalog-fieldname      = 'AUDATC'.
  fieldcatalog-tabname        = 'GT_FINAL'.
  fieldcatalog-seltext_m      = TEXT-022.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR fieldcatalog.

  IF p_chk IS INITIAL.
    fieldcatalog-fieldname      = 'CHECK'.
    fieldcatalog-tabname        = 'GT_FINAL'.
    fieldcatalog-checkbox       = 'X'.
    fieldcatalog-seltext_m      = TEXT-029.
    fieldcatalog-edit           = 'X'.
    APPEND fieldcatalog TO fieldcatalog.
    CLEAR fieldcatalog.
  ENDIF.


  fieldcatalog-fieldname      = 'VBELN'.
  fieldcatalog-tabname        = 'GT_FINAL'.
  fieldcatalog-ref_tabname    = 'VBAK'.
  fieldcatalog-ref_fieldname  = 'VBELN'.
  fieldcatalog-key            = 'X'.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR fieldcatalog.

  fieldcatalog-fieldname      = 'POSNR'.
  fieldcatalog-tabname        = 'GT_FINAL'.
  fieldcatalog-ref_tabname    = 'VBAP'.
  fieldcatalog-ref_fieldname  = 'POSNR'.
  fieldcatalog-key            = 'X'.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR fieldcatalog.

*  fieldcatalog-fieldname      = 'VBELN_VL'.
*  fieldcatalog-tabname        = 'GT_FINAL'.
*  fieldcatalog-ref_tabname    = 'LIKP'.
*  fieldcatalog-ref_fieldname  = 'VBELN'.
*  fieldcatalog-key            = 'X'.
*  fieldcatalog-hotspot        = 1.
*  APPEND fieldcatalog TO fieldcatalog.
*  CLEAR fieldcatalog.
*
*  fieldcatalog-fieldname      = 'POSNR_VL'.
*  fieldcatalog-tabname        = 'GT_FINAL'.
*  fieldcatalog-ref_tabname    = 'LIPS'.
*  fieldcatalog-ref_fieldname  = 'POSNR'.
*  fieldcatalog-key            = 'X'.
*  fieldcatalog-hotspot        = 1.
*  APPEND fieldcatalog TO fieldcatalog.
*  CLEAR fieldcatalog.
*
*  fieldcatalog-fieldname      = 'VBELN_VF'.
*  fieldcatalog-tabname        = 'GT_FINAL'.
*  fieldcatalog-ref_tabname    = 'VBRK'.
*  fieldcatalog-ref_fieldname  = 'VBELN'.
*  fieldcatalog-key            = 'X'.
*  fieldcatalog-hotspot        = 1.
*  APPEND fieldcatalog TO fieldcatalog.
*  CLEAR fieldcatalog.
*
*  fieldcatalog-fieldname      = 'POSNR_VF'.
*  fieldcatalog-tabname        = 'GT_FINAL'.
*  fieldcatalog-ref_tabname    = 'VBRP'.
*  fieldcatalog-ref_fieldname  = 'POSNR'.
*  fieldcatalog-key            = 'X'.
*  fieldcatalog-hotspot        = 1.
*  APPEND fieldcatalog TO fieldcatalog.
*  CLEAR fieldcatalog.

  fieldcatalog-fieldname      = 'AUART'.
  fieldcatalog-tabname        = 'GT_FINAL'.
  fieldcatalog-ref_tabname    = 'VBAK'.
  fieldcatalog-ref_fieldname  = 'AUART'.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR fieldcatalog.

  fieldcatalog-fieldname      = 'AUDAT'.
  fieldcatalog-tabname        = 'GT_FINAL'.
  fieldcatalog-ref_tabname    = 'VBAK'.
  fieldcatalog-ref_fieldname  = 'AUDAT'.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR fieldcatalog.

  fieldcatalog-fieldname      = 'VKORG'.
  fieldcatalog-tabname        = 'GT_FINAL'.
  fieldcatalog-ref_tabname    = 'VBAK'.
  fieldcatalog-ref_fieldname  = 'VKORG'.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR fieldcatalog.

  fieldcatalog-fieldname      = 'VTWEG'.
  fieldcatalog-tabname        = 'GT_FINAL'.
  fieldcatalog-ref_tabname    = 'VBAK'.
  fieldcatalog-ref_fieldname  = 'VTWEG'.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR fieldcatalog.

  fieldcatalog-fieldname      = 'VDATU'.
  fieldcatalog-tabname        = 'GT_FINAL'.
  fieldcatalog-ref_tabname    = 'VBAK'.
  fieldcatalog-ref_fieldname  = 'VDATU'.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR fieldcatalog.

  fieldcatalog-fieldname      = 'MATNR'.
  fieldcatalog-tabname        = 'GT_FINAL'.
  fieldcatalog-ref_tabname    = 'VBAP'.
  fieldcatalog-ref_fieldname  = 'MATNR'.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR fieldcatalog.

  fieldcatalog-fieldname      = 'ARKTX'.
  fieldcatalog-tabname        = 'GT_FINAL'.
  fieldcatalog-ref_tabname    = 'VBAP'.
  fieldcatalog-ref_fieldname  = 'ARKTX'.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR fieldcatalog.

  fieldcatalog-fieldname      = 'CHARG'.
  fieldcatalog-tabname        = 'GT_FINAL'.
  fieldcatalog-ref_tabname    = 'VBAP'.
  fieldcatalog-ref_fieldname  = 'CHARG'.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR fieldcatalog.

  fieldcatalog-fieldname      = 'SPART'.
  fieldcatalog-tabname        = 'GT_FINAL'.
  fieldcatalog-ref_tabname    = 'VBAP'.
  fieldcatalog-ref_fieldname  = 'SPART'.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR fieldcatalog.

  fieldcatalog-fieldname      = 'WERKS'.
  fieldcatalog-tabname        = 'GT_FINAL'.
  fieldcatalog-ref_tabname    = 'VBAP'.
  fieldcatalog-ref_fieldname  = 'WERKS'.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR fieldcatalog.

  fieldcatalog-fieldname      = 'LGORT'.
  fieldcatalog-tabname        = 'GT_FINAL'.
  fieldcatalog-ref_tabname    = 'VBAP'.
  fieldcatalog-ref_fieldname  = 'LGORT'.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR fieldcatalog.

  fieldcatalog-fieldname      = 'FKART'.
  fieldcatalog-tabname        = 'GT_FINAL'.
  fieldcatalog-ref_tabname    = 'VBRK'.
  fieldcatalog-ref_fieldname  = 'FKART'.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR fieldcatalog.

  fieldcatalog-fieldname      = 'FKDAT'.
  fieldcatalog-tabname        = 'GT_FINAL'.
  fieldcatalog-ref_tabname    = 'VBRK'.
  fieldcatalog-ref_fieldname  = 'FKDAT'.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR fieldcatalog.

  fieldcatalog-fieldname      = 'KDGRP'.
  fieldcatalog-tabname        = 'GT_FINAL'.
  fieldcatalog-ref_tabname    = 'VBRK'.
  fieldcatalog-ref_fieldname  = 'KDGRP'.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR fieldcatalog.

  fieldcatalog-fieldname      = 'KTEXT'.
  fieldcatalog-tabname        = 'GT_FINAL'.
  fieldcatalog-ref_tabname    = 'T189T'.
  fieldcatalog-ref_fieldname  = 'PTEXT'.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR fieldcatalog.

  fieldcatalog-fieldname      = 'PLTYP'.
  fieldcatalog-tabname        = 'GT_FINAL'.
  fieldcatalog-ref_tabname    = 'VBRK'.
  fieldcatalog-ref_fieldname  = 'PLTYP'.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR fieldcatalog.

  fieldcatalog-fieldname      = 'PTEXT'.
  fieldcatalog-tabname        = 'GT_FINAL'.
  fieldcatalog-ref_tabname    = 'T189T'.
  fieldcatalog-ref_fieldname  = 'PTEXT'.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR fieldcatalog.

  fieldcatalog-fieldname      = 'SH_QTY'.
  fieldcatalog-tabname        = 'GT_FINAL'.
  fieldcatalog-seltext_m      =  TEXT-011.
  fieldcatalog-do_sum         = 'X'.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR fieldcatalog.

  fieldcatalog-fieldname      = 'DIS_QTY'.
  fieldcatalog-tabname        = 'GT_FINAL'.
  fieldcatalog-seltext_m      =  TEXT-014.
  fieldcatalog-do_sum         = 'X'.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR fieldcatalog.

  fieldcatalog-fieldname      = 'PK_QTY'.
  fieldcatalog-tabname        = 'GT_FINAL'.
  fieldcatalog-seltext_m      =  TEXT-020.
  fieldcatalog-do_sum         = 'X'.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR fieldcatalog.

  fieldcatalog-fieldname      = 'BAL_QTY'.
  fieldcatalog-tabname        = 'GT_FINAL'.
  fieldcatalog-seltext_m      =  TEXT-015.
  fieldcatalog-do_sum         = 'X'.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR fieldcatalog.

  fieldcatalog-fieldname      = 'TOL_QTY'.
  fieldcatalog-tabname        = 'GT_FINAL'.
  fieldcatalog-seltext_m      =  TEXT-030.
  fieldcatalog-do_sum         = 'X'.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR fieldcatalog.

  fieldcatalog-fieldname      = 'ZMENG'.
  fieldcatalog-tabname        = 'GT_FINAL'.
  fieldcatalog-seltext_m      = TEXT-019.
  fieldcatalog-do_sum         = 'X'.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR fieldcatalog.

  fieldcatalog-fieldname      = 'VRKME'.
  fieldcatalog-tabname        = 'GT_FINAL'.
  fieldcatalog-ref_tabname    = 'VBAP'.
  fieldcatalog-ref_fieldname  = 'VRKME'.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR fieldcatalog.

  fieldcatalog-fieldname      = 'LFART'.
  fieldcatalog-tabname        = 'GT_FINAL'.
  fieldcatalog-ref_tabname    = 'LIKP'.
  fieldcatalog-ref_fieldname  = 'LFART'.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR fieldcatalog.

  fieldcatalog-fieldname      = 'VTEXT'.
  fieldcatalog-tabname        = 'GT_FINAL'.
  fieldcatalog-ref_tabname    = 'TVLKT'.
  fieldcatalog-ref_fieldname  = 'VTEXT'.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR fieldcatalog.

  fieldcatalog-fieldname      = 'ZZGRADE'.
  fieldcatalog-tabname        = 'GT_FINAL'.
  fieldcatalog-ref_tabname    = 'VBAP'.
  fieldcatalog-ref_fieldname  = 'ZZGRADE'.
  fieldcatalog-seltext_m      =  TEXT-023.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR fieldcatalog.

  fieldcatalog-fieldname      = 'GDESC'.
  fieldcatalog-tabname        = 'GT_FINAL'.
  fieldcatalog-seltext_m      =  TEXT-016.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR fieldcatalog.

  fieldcatalog-fieldname      = 'ZZGRAD1'.
  fieldcatalog-tabname        = 'GT_FINAL'.
  fieldcatalog-ref_tabname    = 'VBAP'.
  fieldcatalog-ref_fieldname  = 'ZZGRAD1'.
  fieldcatalog-seltext_m      =  TEXT-024.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR fieldcatalog.

  fieldcatalog-fieldname      = 'ZZGRAD2'.
  fieldcatalog-tabname        = 'GT_FINAL'.
  fieldcatalog-ref_tabname    = 'VBAP'.
  fieldcatalog-ref_fieldname  = 'ZZGRAD2'.
  fieldcatalog-seltext_m      =  TEXT-025.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR fieldcatalog.

  fieldcatalog-fieldname      = 'ZZSIZE'.
  fieldcatalog-tabname        = 'GT_FINAL'.
  fieldcatalog-ref_tabname    = 'VBAP'.
  fieldcatalog-ref_fieldname  = 'ZZSIZE'.
  fieldcatalog-seltext_m      =  TEXT-026.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR fieldcatalog.

  fieldcatalog-fieldname      = 'ZZSIZ1'.
  fieldcatalog-tabname        = 'GT_FINAL'.
  fieldcatalog-ref_tabname    = 'VBAP'.
  fieldcatalog-ref_fieldname  = 'ZZSIZ1'.
  fieldcatalog-seltext_m      =  TEXT-027.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR fieldcatalog.

  fieldcatalog-fieldname      = 'ZZSIZ2'.
  fieldcatalog-tabname        = 'GT_FINAL'.
  fieldcatalog-ref_tabname    = 'VBAP'.
  fieldcatalog-ref_fieldname  = 'ZZSIZ2'.
  fieldcatalog-seltext_m      =  TEXT-028.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR fieldcatalog.

  fieldcatalog-fieldname      = 'ZZPKREM'.
  fieldcatalog-tabname        = 'GT_FINAL'.
  fieldcatalog-ref_tabname    = 'VBAP'.
  fieldcatalog-ref_fieldname  = 'ZZPKREM'.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR fieldcatalog.

  fieldcatalog-fieldname      = 'BP_KUNNR'.
  fieldcatalog-tabname        = 'GT_FINAL'.
  fieldcatalog-seltext_m      =  TEXT-004.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR fieldcatalog.

  fieldcatalog-fieldname      = 'BP_NAME1'.
  fieldcatalog-tabname        = 'GT_FINAL'.
  fieldcatalog-seltext_m      =  TEXT-005.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR fieldcatalog.

  fieldcatalog-fieldname      = 'SH_KUNNR'.
  fieldcatalog-tabname        = 'GT_FINAL'.
  fieldcatalog-seltext_m      =  TEXT-006.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR fieldcatalog.

  fieldcatalog-fieldname      = 'SH_NAME1'.
  fieldcatalog-tabname        = 'GT_FINAL'.
  fieldcatalog-seltext_m      =  TEXT-007.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR fieldcatalog.

  fieldcatalog-fieldname      = 'SH_NAME2'.                         "Ship-to-party Name Harshal
  fieldcatalog-tabname        = 'GT_FINAL'.
  fieldcatalog-ref_tabname    = 'ADRC'.
  fieldcatalog-ref_fieldname  = 'NAME2'.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR fieldcatalog.

  fieldcatalog-fieldname      = 'STR_SUPPL1'.
  fieldcatalog-tabname        = 'GT_FINAL'.
  fieldcatalog-ref_tabname    = 'ADRC'.
  fieldcatalog-ref_fieldname  = 'STR_SUPPL1'.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR fieldcatalog.

  fieldcatalog-fieldname      = 'ORT01'.
  fieldcatalog-tabname        = 'GT_FINAL'.
  fieldcatalog-ref_tabname    = 'KNA1'.
  fieldcatalog-ref_fieldname  = 'ORT01'.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR fieldcatalog.                                                   "End Harshal

  fieldcatalog-fieldname      = 'AG_KUNNR'.
  fieldcatalog-tabname        = 'GT_FINAL'.
  fieldcatalog-seltext_m      =  TEXT-008.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR fieldcatalog.

  fieldcatalog-fieldname      = 'AG_NAME1'.
  fieldcatalog-tabname        = 'GT_FINAL'.
  fieldcatalog-seltext_m      =  TEXT-009.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR fieldcatalog.

  fieldcatalog-fieldname      = 'REGION'.
  fieldcatalog-tabname        = 'GT_FINAL'.
  fieldcatalog-seltext_m      =  TEXT-010.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR fieldcatalog.

  fieldcatalog-fieldname      = 'TYPE'.
  fieldcatalog-tabname        = 'GT_FINAL'.
  fieldcatalog-seltext_m      =  TEXT-012.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR fieldcatalog.

  fieldcatalog-fieldname      = 'RATE'.
  fieldcatalog-tabname        = 'GT_FINAL'.
  fieldcatalog-seltext_m      =  TEXT-013.
  fieldcatalog-do_sum         = 'X'.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR fieldcatalog.

  fieldcatalog-fieldname      = 'CLABS'.
  fieldcatalog-tabname        = 'GT_FINAL'.
  fieldcatalog-seltext_m      =  TEXT-017.
  fieldcatalog-do_sum         = 'X'.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR fieldcatalog.
ENDFORM.                    " BUILD_FIELDCATALOG
*&---------------------------------------------------------------------*
*&      Form  BUILD_LAYOUT
*&---------------------------------------------------------------------*
FORM build_layout .

  gd_layout-colwidth_optimize = 'X'.
  gd_layout-zebra             = 'X'.
  gd_layout-box_fieldname     = 'SEL'.

  gs_sort-fieldname = 'VBELN'.
  gs_sort-tabname   = 'GT_FINAL'.
  APPEND gs_sort TO gt_sort.

ENDFORM.                    " BUILD_LAYOUT


*&---------------------------------------------------------------------*
*&      Form  DISPLAY_ALV_REPORT
*&---------------------------------------------------------------------*
FORM display_alv_report .
  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
    EXPORTING
*     I_INTERFACE_CHECK        = ' '
*     I_BYPASSING_BUFFER       = ' '
*     I_BUFFER_ACTIVE          = ' '
      i_callback_program       = sy-repid
      i_callback_pf_status_set = 'SET_PF_STATUS'
      i_callback_user_command  = 'USER_COMMAND'
*     i_callback_top_of_page   = 'TOP_OF_PAGE'
*     I_CALLBACK_HTML_TOP_OF_PAGE       = ' '
*     I_CALLBACK_HTML_END_OF_LIST       = ' '
*     I_STRUCTURE_NAME         =
*     I_BACKGROUND_ID          = ' '
*     I_GRID_TITLE             =
*     I_GRID_SETTINGS          =
      is_layout                = gd_layout
      it_fieldcat              = fieldcatalog[]
*     IT_EXCLUDING             =
*     IT_SPECIAL_GROUPS        =
      it_sort                  = gt_sort[]
*     IT_FILTER                =
*     IS_SEL_HIDE              =
      i_default                = 'X'
      i_save                   = 'A'
      is_variant               = g_variant
*     IT_EVENTS                =
*     IT_EVENT_EXIT            =
*     IS_PRINT                 =
*     IS_REPREP_ID             =
*     I_SCREEN_START_COLUMN    = 0
*     I_SCREEN_START_LINE      = 0
*     I_SCREEN_END_COLUMN      = 0
*     I_SCREEN_END_LINE        = 0
*     I_HTML_HEIGHT_TOP        = 0
*     I_HTML_HEIGHT_END        = 0
*     IT_ALV_GRAPHICS          =
*     IT_HYPERLINK             =
*     IT_ADD_FIELDCAT          =
*     IT_EXCEPT_QINFO          =
*     IR_SALV_FULLSCREEN_ADAPTER        =
*   IMPORTING
*     E_EXIT_CAUSED_BY_CALLER  =
*     ES_EXIT_CAUSED_BY_USER   =
    TABLES
      t_outtab                 = gt_final[]
*   EXCEPTIONS
*     PROGRAM_ERROR            = 1
*     OTHERS                   = 2
    .
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
    WHEN 'DOWNLOAD'.
      BREAK abap_dev.

      PERFORM download_so_file.

      PERFORM get_box_data.

      PERFORM download_file_stock.
  ENDCASE.
ENDFORM.                    "user_command

*&---------------------------------------------------------------------*
*&      Form  PROCESS_DATA
*&---------------------------------------------------------------------*
FORM process_data .

  LOOP AT gt_vbap INTO gs_vbap.
    CLEAR gs_vbak.

    READ TABLE gt_vbak INTO gs_vbak WITH KEY vbeln = gs_vbap-vbeln.
    IF sy-subrc EQ 0.
      CLEAR gs_vbakc.
**      262012
****      IF gs_vbak-vgbel IS NOT INITIAL.
*****        READ TABLE gt_vbakc INTO gs_vbakc WITH KEY vbeln = gs_vbak-vgbel.
*****        IF sy-subrc NE 0.
*****          CONTINUE.
*****        ENDIF.
****        READ TABLE gt_vbapc INTO gs_vbapc WITH KEY vbeln = gs_vbap-vgbel
****                                                   posnr = gs_vbap-vgpos.
****        IF sy-subrc NE 0.
****          CONTINUE.
****        ENDIF.
****      ENDIF.
      gs_final-augru = gs_vbak-augru. " added by pranay on 26.6.2012
      CLEAR gs_vbakc.
      READ TABLE gt_vbakc INTO gs_vbakc WITH KEY vbeln = gs_vbak-vgbel.
      IF sy-subrc EQ 0.
        MOVE gs_vbakc-audat TO gs_final-audatc.
        CLEAR gs_vbapc.
*        READ TABLE gt_vbapc INTO gs_vbapc WITH KEY vbeln = gs_vbakc-vbeln.
        READ TABLE gt_vbapc INTO gs_vbapc WITH KEY vbeln = gs_vbakc-vbeln
                                                   posnr = gs_vbap-vgpos.
        IF sy-subrc EQ 0.

          MOVE gs_vbapc-abgru TO gs_final-abgruc.       " Rejection Reason ( Contract )
          MOVE gs_vbapc-zmeng TO gs_final-zmeng.        " Contract Quantity
          MOVE gs_vbapc-posnr TO gs_final-vgpos.        " Contract Item
        ENDIF.
      ENDIF.

      MOVE gs_vbak-auart TO gs_final-auart.       " Sales Document Type
      MOVE gs_vbak-audat TO gs_final-audat.       " Document Date
      MOVE gs_vbak-vkorg TO gs_final-vkorg.       " Sales Org.
      MOVE gs_vbak-vtweg TO gs_final-vtweg.       " Distr. Channel
      MOVE gs_vbak-vdatu TO gs_final-vdatu.       " Request.dlv.dt
      MOVE gs_vbak-vgbel TO gs_final-vgbel.       " Reference doc ( Contract ).

      CLEAR gs_vbpa.
      READ TABLE gt_vbpa INTO gs_vbpa WITH KEY vbeln = gs_vbak-vbeln
                                               parvw = 'RE'.          "Bill-to-party
      IF sy-subrc EQ 0.
        MOVE gs_vbpa-kunnr TO gs_final-bp_kunnr.
        CLEAR gs_kna1.
        READ TABLE gt_kna1 INTO gs_kna1 WITH KEY kunnr = gs_vbpa-kunnr.
        IF sy-subrc EQ 0.
          MOVE gs_kna1-name1 TO gs_final-bp_name1.

          CLEAR gs_kna1.
          " CLEAR GS_J_1IMOCUST. auto changed

          READ TABLE gt_kna1 INTO gs_kna1
          " READ TABLE GT_J_1IMOCUST INTO GS_J_1IMOCUST auto changed
                                             WITH KEY kunnr = gs_kna1-kunnr.

          CLEAR gs_vbkd.
          READ TABLE gt_vbkd INTO gs_vbkd
                             WITH KEY vbeln = gs_vbap-vbeln.
          IF gs_vbkd-pltyp = '02' .
            gs_final-type = 'Retail Invoice'.
          ELSE.
            IF gs_kna1-j_1icstno IS INITIAL AND
            " IF GS_J_1IMOCUST-J_1ICSTNO IS INITIAL AND auto changed
            gs_kna1-j_1ilstno IS INITIAL.
              " GS_J_1IMOCUST-J_1ILSTNO IS INITIAL. auto changed
              gs_final-type = 'Retail Invoice'.
            ELSE.
              gs_final-type = 'Tax Invoice'.
            ENDIF.
          ENDIF.
        ENDIF.
      ENDIF.

      CLEAR gs_vbpa.
      READ TABLE gt_vbpa INTO gs_vbpa WITH KEY vbeln = gs_vbak-vbeln
                                               parvw = 'WE'.          "Ship-to-party
      IF sy-subrc EQ 0.
        MOVE gs_vbpa-kunnr TO gs_final-sh_kunnr.
        CLEAR gs_kna1.
        READ TABLE gt_kna1 INTO gs_kna1 WITH KEY kunnr = gs_vbpa-kunnr.
        IF sy-subrc EQ 0.

          MOVE gs_kna1-name1 TO gs_final-sh_name1.
          MOVE gs_kna1-name2 TO gs_final-sh_name2.                            "Start Harshal
*          MOVE gs_kna1-stras TO gs_final-stras.
          MOVE gs_kna1-ort01 TO gs_final-ort01.

          CLEAR gs_adrc.
          READ TABLE gt_adrc INTO gs_adrc WITH KEY addrnumber = gs_kna1-adrnr.
          IF sy-subrc EQ 0.
            MOVE gs_adrc-str_suppl1 TO gs_final-str_suppl1.
          ENDIF.

        ENDIF.
      ENDIF.

      CLEAR gs_vbpa.
      READ TABLE gt_vbpa INTO gs_vbpa WITH KEY vbeln = gs_vbak-vbeln
                                               parvw = 'ZA'.          "Agent
      IF sy-subrc EQ 0.
        MOVE gs_vbpa-kunnr TO gs_final-ag_kunnr.
        CLEAR gs_kna1.
        READ TABLE gt_kna1 INTO gs_kna1 WITH KEY kunnr = gs_vbpa-kunnr.
        IF sy-subrc EQ 0.
          MOVE gs_kna1-name1 TO gs_final-ag_name1.
        ENDIF.
      ENDIF.

      CLEAR gs_vbpa.
      READ TABLE gt_vbpa INTO gs_vbpa WITH KEY vbeln = gs_vbak-vbeln
                                               parvw = 'AG'.          "Sold-to-party
      IF sy-subrc EQ 0.
        MOVE gs_vbpa-kunnr TO gs_final-sh_kunnr.
        CLEAR gs_kna1.
        READ TABLE gt_kna1 INTO gs_kna1 WITH KEY kunnr = gs_vbpa-kunnr.
        IF sy-subrc EQ 0.
          IF gs_kna1-regio EQ '06'.             " Gujarat
            gs_final-region = 'Local'.          " Region
          ELSE.
            gs_final-region = 'Out Station'.    " Region
          ENDIF.
        ENDIF.
      ENDIF.

      CLEAR gs_grade.
      READ TABLE gt_grade INTO gs_grade WITH KEY gcode = gs_vbap-zzgrade.
      IF sy-subrc EQ 0.
        MOVE gs_grade-gdesc TO gs_final-gdesc.  " Grade Desc.
      ENDIF.

    ENDIF.

    CLEAR gs_lips.
    READ TABLE gt_lips INTO gs_lips WITH KEY vgbel = gs_vbap-vbeln
                                             vgpos = gs_vbap-posnr.
    IF sy-subrc EQ 0.

      CLEAR gs_likp.
      READ TABLE gt_likp INTO gs_likp WITH KEY vbeln = gs_lips-vbeln.
      IF sy-subrc EQ 0.
        gs_final-lfart = gs_likp-lfart.
        IF gt_likp[] IS NOT INITIAL.
          READ TABLE gt_tvlkt INTO gs_tvlkt WITH KEY lfart = gs_final-lfart.
          IF sy-subrc EQ 0.
            gs_final-vtext = gs_tvlkt-vtext.
          ENDIF.
        ENDIF.
      ENDIF.

      gs_final-vbeln_vl = gs_lips-vbeln.
      gs_final-posnr_vl = gs_lips-posnr.
      CLEAR gs_vbrp.
      READ TABLE gt_vbrp INTO gs_vbrp WITH KEY vgbel = gs_lips-vbeln
                                               vgpos = gs_lips-posnr.
      IF sy-subrc EQ 0.

        gs_final-vbeln_vf = gs_vbrp-vbeln.
        gs_final-posnr_vf = gs_vbrp-posnr.

        CLEAR gs_vbrk.
        READ TABLE gt_vbrk INTO gs_vbrk WITH KEY vbeln = gs_vbrp-vbeln.
        IF sy-subrc EQ 0.
          gs_final-fkart = gs_vbrk-fkart.
          gs_final-fkdat = gs_vbrk-fkdat.
          gs_final-kdgrp = gs_vbrk-kdgrp.
          gs_final-pltyp = gs_vbrk-pltyp.

          CLEAR gs_t189t.
          READ TABLE gt_t189t INTO gs_t189t WITH KEY pltyp = gs_vbrk-pltyp.
          IF sy-subrc EQ 0.
            gs_final-ptext = gs_t189t-ptext.
          ENDIF.

          CLEAR gs_t151t.
          READ TABLE gt_t151t INTO gs_t151t WITH KEY kdgrp = gs_vbrk-kdgrp.
          IF sy-subrc EQ 0.
            gs_final-ktext = gs_t151t-ktext.
          ENDIF.
        ENDIF.
      ENDIF.
    ENDIF.

    CLEAR gs_prcd_elements.
    " CLEAR GS_KONV. auto changed
    IF gs_final-vtweg EQ '20'.      " Export
      READ TABLE gt_prcd_elements INTO gs_prcd_elements WITH KEY knumv = gs_vbak-knumv
      " READ TABLE GT_KONV INTO GS_KONV WITH KEY KNUMV = GS_VBAK-KNUMV auto changed
                                                   kposn = gs_vbap-posnr
                                                   kschl = 'ZCIF'.
      IF sy-subrc EQ 0.
        gs_final-rate = gs_prcd_elements-kbetr. " RATE
        " GS_FINAL-RATE = GS_KONV-KBETR. " RATE auto changed
      ENDIF.
    ELSE.
      READ TABLE gt_prcd_elements INTO gs_prcd_elements WITH KEY knumv = gs_vbak-knumv
      " READ TABLE GT_KONV INTO GS_KONV WITH KEY KNUMV = GS_VBAK-KNUMV auto changed
                                                     kposn = gs_vbap-posnr
                                                     kschl = 'ZR00'.
      IF sy-subrc EQ 0.
        gs_final-rate = gs_prcd_elements-kbetr. " RATE
        " GS_FINAL-RATE = GS_KONV-KBETR. " RATE auto changed
      ENDIF.
    ENDIF.
    LOOP AT gt_lips INTO gs_lips WHERE vgbel EQ gs_vbap-vbeln AND
                                       vgpos EQ gs_vbap-posnr.

      ADD gs_lips-lfimg TO gs_final-dis_qty.    " Dispach quantity

    ENDLOOP.

    CLEAR gs_mchb.
    READ TABLE gt_mchb INTO gs_mchb WITH KEY matnr = gs_vbap-matnr
                                             werks = gs_vbap-werks
                                             lgort = gs_vbap-lgort
                                             charg = gs_vbap-charg.
    IF sy-subrc EQ 0.
      MOVE gs_mchb-clabs TO gs_final-clabs.     " Valuated Unrestricted-Use Stock
    ENDIF.

    CLEAR gs_vbup.
    READ TABLE gt_vbup INTO gs_vbup WITH KEY vbeln = gs_vbap-vbeln
                                             posnr = gs_vbap-posnr.
    IF sy-subrc EQ 0.
      MOVE gs_vbup-gbsta TO gs_final-gbsta.
    ENDIF.

    CLEAR: gs_sdtol.
    READ TABLE gt_sdtol INTO gs_sdtol
               WITH KEY vkorg = gs_vbak-vkorg
                        vtweg = gs_vbak-vtweg
                        spart = gs_vbak-spart.
    IF sy-subrc EQ 0.
      gs_final-tol_qty = gs_sdtol-uptol.
    ENDIF.

    MOVE gs_vbap-vbeln    TO gs_final-vbeln.       " Sales Document
    MOVE gs_vbap-posnr    TO gs_final-posnr.       " Item
    MOVE gs_vbap-matnr    TO gs_final-matnr.       " Material Number
    MOVE gs_vbap-arktx    TO gs_final-arktx.       " Material Desc.
    MOVE gs_vbap-abgru    TO gs_final-abgru.       " Rejection Reason ( Order )
    MOVE gs_vbap-charg    TO gs_final-charg.       " Batch Number
    MOVE gs_vbap-spart    TO gs_final-spart.       " Division
    MOVE gs_vbap-gsber    TO gs_final-gsber.       " Business Area
    MOVE gs_vbap-kwmeng   TO gs_final-kwmeng.      " Quantity
    MOVE gs_vbap-vrkme    TO gs_final-vrkme.       " Sales unit
    MOVE gs_vbap-werks    TO gs_final-werks.       " Plant
    MOVE gs_vbap-lgort    TO gs_final-lgort.       " Stor. Location
    MOVE gs_vbap-zzpkrem  TO gs_final-zzpkrem.     " Packing Remarks
    MOVE gs_vbap-zzgrade  TO gs_final-zzgrade.     " Grade one
    MOVE gs_vbap-zzgrad1  TO gs_final-zzgrad1.     " Grade two
    MOVE gs_vbap-zzgrad2  TO gs_final-zzgrad2.     " Grade three
    MOVE gs_vbap-zzsize   TO gs_final-zzsize.      " Size one
    MOVE gs_vbap-zzsiz1   TO gs_final-zzsiz1.      " Size two
    MOVE gs_vbap-zzsiz2   TO gs_final-zzsiz2.      " Size three
    MOVE gs_vbap-kwmeng   TO gs_final-sh_qty.        " Sch. quantity


    gs_final-bal_qty = gs_final-sh_qty - gs_final-dis_qty. " Dispach quantity

    SELECT SUM( netwt ) FROM zpp_pack
                        INTO gs_final-pk_qty
                        WHERE vbeln EQ gs_final-vbeln AND
                              posnr EQ gs_final-posnr.

    APPEND gs_final TO gt_final.

    CLEAR gs_final.

  ENDLOOP.

* AN EMPTY RANGE MEANS THE OPPOSITE HERE TO WHAT IT MEANS IN OPEN SQL.
* (03.09.2026)
*
* Open SQL drops a WHERE condition whose range is empty, so
* "WHERE vbeln IN s_so" with an empty S_SO selects EVERYTHING. An
* internal-table WHERE does not: IN over an empty selection table is
* FALSE, so NOT IN is TRUE, and this statement deleted every row of
* GT_FINAL on any run that left the Agent field blank.
*
* The OData path always leaves it blank - the SUBMIT in
* ZCL_PICK_DOWNLOAD_DPC_EXT passes S_SO, P_CHK and P_SO/P_HU and
* nothing else - so the Scan Suite Packing List reported "No open items
* found" for every sales order on KSQ. Order 5126031533 was the proof:
* VBTYP C, AUART OR, VKORG 1000, V_VBRK_VKO returning RC 0 in
* STAUTHTRACE, passing every condition on the GT_VBAK select and every
* branch of the loop above, and still absent from the result.
*
* Interactively the report has the same behaviour and always has - a run
* from SE38 with only a Sales Document filled answers "No data found".
* It went unnoticed because its users fill the Agent field.
*
* THIS IS THE SAME MISREADING AS THE FOR ALL ENTRIES GUARDS IN GET_DATA,
* pointing the other way: an empty driver table there reads the whole
* table, an empty range here deletes the whole result. One form, both
* traps. Neither is a filter that "does nothing" when it is empty.
  IF s_agt[] IS NOT INITIAL.
    DELETE gt_final[] WHERE ag_kunnr NOT IN s_agt.
  ENDIF.



ENDFORM.                    " PROCESS_DATA

*&---------------------------------------------------------------------*
*&      Form  top_of_page
*&---------------------------------------------------------------------*

FORM top_of_page.
  DATA: l_date TYPE char10,
        l_time TYPE char10.

  DATA: it_heading TYPE slis_t_listheader,
        wa_heading LIKE LINE OF it_heading.

  wa_heading-info = 'Sales Order Register'.
  wa_heading-typ  = 'H'.
  APPEND wa_heading TO it_heading.
  CLEAR wa_heading.

  CLEAR l_date.
  WRITE sy-datum TO l_date DD/MM/YYYY.

  wa_heading-key  = 'Run Date :'.
  wa_heading-typ  = 'S'.
  wa_heading-info = l_date.
  APPEND wa_heading TO it_heading.
  CLEAR wa_heading.

  wa_heading-key  = 'Run By :'.
  wa_heading-typ  = 'S'.
  wa_heading-info = sy-uname.
  APPEND wa_heading TO it_heading.
  CLEAR wa_heading.

  CALL FUNCTION 'REUSE_ALV_COMMENTARY_WRITE'
    EXPORTING
      it_list_commentary = it_heading[]
      i_logo             = 'ZKEJ_SMALL'
*     I_END_OF_LIST_GRID =
*     I_ALV_FORM         =
    .

ENDFORM.                    "top_of_page
*&---------------------------------------------------------------------*
*&      Form  PAI_OF_SELECTION_SCREEN
*&---------------------------------------------------------------------*
FORM pai_of_selection_screen .
  IF NOT p_vari IS INITIAL.
    MOVE g_variant TO gx_variant.
    MOVE p_vari TO gx_variant-variant.
    CALL FUNCTION 'REUSE_ALV_VARIANT_EXISTENCE'
      EXPORTING
        i_save     = g_save
      CHANGING
        cs_variant = gx_variant.
    g_variant = gx_variant.
  ELSE.
    PERFORM initialize_variant.
  ENDIF.
ENDFORM.                    " PAI_OF_SELECTION_SCREEN
*&---------------------------------------------------------------------*
*&      Form  INITIALIZE_VARIANT
*&---------------------------------------------------------------------*
FORM initialize_variant .
  g_save = 'A'.
  CLEAR g_variant.
  g_variant-report = sy-repid.
  gx_variant = g_variant.
  CALL FUNCTION 'REUSE_ALV_VARIANT_DEFAULT_GET'
    EXPORTING
      i_save     = g_save
    CHANGING
      cs_variant = gx_variant
    EXCEPTIONS
      not_found  = 2.
  IF sy-subrc = 0.
    p_vari = gx_variant-variant.
  ENDIF.
  gd_layout-get_selinfos = 'X'.
  gd_layout-group_change_edit = 'X'.
ENDFORM.                    " INITIALIZE_VARIANT
*&---------------------------------------------------------------------*
*&      Form  set_pf_status
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM set_pf_status USING rt_extab TYPE slis_t_extab.
  SET PF-STATUS 'PF_STATUS'.
ENDFORM.                    "set_pf_status
*&---------------------------------------------------------------------*
*&      Form  OPEN_CLOSE
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM open_close .
  SORT gt_final BY vgbel vbeln posnr.

  LOOP AT gt_final INTO gs_final.
    gs_contract-vgbel   = gs_final-vgbel.
    gs_contract-vgpos   = gs_final-vgpos.
    gs_contract-tot_dis = gs_final-dis_qty.
    COLLECT gs_contract INTO gt_contract.
  ENDLOOP.

  DELETE gt_contract WHERE vgbel IS INITIAL. "ADDED BY PRANAY 28042012

  gt_temp[] = gt_final[].

  LOOP AT gt_temp INTO gs_temp.
    DATA :   no TYPE i.

    CLEAR gs_sdtol.
    READ TABLE gt_sdtol INTO gs_sdtol
               WITH KEY vkorg = gs_temp-vkorg
                        vtweg = gs_temp-vtweg
                        spart = gs_temp-spart
                        auart = gs_temp-auart.

    " Logic to delete orders whose dispatch qty is greater than order qty plus
    " upper tolerance i.e. maintained in ZSDTOL table.

    IF r_open EQ 'X'.
      IF gs_temp-abgru IS INITIAL.
        IF gs_temp-kwmeng < gs_sdtol-uptol.
          IF gs_temp-kwmeng <= gs_temp-dis_qty.
            DELETE gt_final WHERE vbeln EQ gs_temp-vbeln AND
                                  posnr EQ gs_temp-posnr.
          ENDIF.
        ELSE.
          IF gs_temp-kwmeng <= gs_temp-dis_qty + gs_sdtol-uptol.
            DELETE gt_final WHERE vbeln EQ gs_temp-vbeln AND
                                  posnr EQ gs_temp-posnr.
          ENDIF.
        ENDIF.
      ELSE.
        DELETE gt_final WHERE abgru IS NOT INITIAL.
      ENDIF.
    ELSEIF r_close EQ 'X'.
      IF gs_temp-augru IS INITIAL.
        IF gs_temp-abgru IS INITIAL.
          IF gs_temp-kwmeng < gs_sdtol-uptol.
            IF gs_temp-kwmeng > gs_temp-dis_qty.
              so = 1.
*          DELETE gt_final WHERE vbeln EQ gs_temp-vbeln.
            ENDIF.
          ELSEIF gs_temp-kwmeng > gs_temp-dis_qty + gs_sdtol-uptol.
            so = 1.
*          DELETE gt_final WHERE vbeln EQ gs_temp-vbeln.
          ENDIF.
        ELSE.
          no = 1.
        ENDIF.
      ENDIF.
    ENDIF.

    " Logic to delete contracts whose total dispatch qty against all orders
    " is greater than contract qty plus upper tolerance i.e. maintained in ZSDTOL

    AT END OF vgbel.
      CLEAR gs_contract.
      READ TABLE gt_contract INTO gs_contract
                             WITH KEY vgbel = gs_temp-vgbel
                                      vgpos = gs_temp-vgpos.

      IF sy-subrc = 0.
        IF r_open EQ 'X'.
          IF gs_temp-abgruc IS INITIAL.
            IF gs_temp-zmeng < gs_sdtol-uptol.
              IF gs_temp-zmeng <= gs_contract-tot_dis.
                DELETE gt_final WHERE vgbel EQ gs_temp-vgbel  AND
                                      vbeln EQ gs_temp-vbeln AND
                                      posnr EQ gs_temp-posnr.
              ENDIF.
            ELSEIF gs_temp-zmeng <= gs_contract-tot_dis + gs_sdtol-uptol.
              DELETE gt_final WHERE vgbel EQ gs_temp-vgbel  AND
                                    vbeln EQ gs_temp-vbeln AND
                                    posnr EQ gs_temp-posnr.

            ENDIF.
          ELSE.
            DELETE gt_final WHERE abgruc IS NOT INITIAL.
          ENDIF.
        ELSEIF r_close EQ 'X'.
          IF gs_temp-augru IS INITIAL.
            IF gs_temp-abgruc IS INITIAL AND no IS INITIAL.
              IF gs_temp-zmeng < gs_sdtol-uptol.
                IF gs_temp-zmeng > gs_contract-tot_dis.
                  DELETE gt_final WHERE vgbel EQ gs_temp-vgbel AND
                                        vbeln EQ gs_temp-vbeln AND
                                        posnr EQ gs_temp-posnr.
                ENDIF.
              ELSEIF gs_temp-zmeng > gs_contract-tot_dis + gs_sdtol-uptol.
                DELETE gt_final WHERE vgbel EQ gs_temp-vgbel AND
                                      vbeln EQ gs_temp-vbeln AND
                                      posnr EQ gs_temp-posnr.
              ENDIF.
              IF so = 1.
                DELETE gt_final WHERE vgbel EQ gs_temp-vgbel AND
                                      vbeln EQ gs_temp-vbeln AND
                                      posnr EQ gs_temp-posnr.
                CLEAR so.
              ENDIF.
            ENDIF.
          ENDIF.



        ENDIF.
      ENDIF.

      IF so = 1 AND r_close = 'X'.
        DELETE gt_final WHERE vgbel EQ gs_temp-vgbel AND
                              vbeln EQ gs_temp-vbeln AND
                              posnr EQ gs_temp-posnr.
        CLEAR so.
      ENDIF.
    ENDAT.
  ENDLOOP.

  IF r_open EQ 'X'.
    DELETE gt_final WHERE augru IS NOT INITIAL.
    DELETE gt_final WHERE abgru  IS NOT INITIAL.
    DELETE gt_final WHERE abgruc IS NOT INITIAL.
  ENDIF.

*  IF r_open EQ 'X'.
**    DELETE gt_final[] WHERE abgru  IS INITIAL.   " For Manual Completion
*    DELETE gt_final[] WHERE abgruc IS NOT INITIAL.
*  ELSEIF r_close EQ 'X'.
**    DELETE gt_final[] WHERE abgru  IS NOT INITIAL.
*    DELETE gt_final[] WHERE abgruc IS INITIAL.
*  ENDIF.

ENDFORM.                    " OPEN_CLOSE
*&---------------------------------------------------------------------*
*&      Form  DOWNLOAD_FILE
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM download_so_file .
  REFRESH: gt_down_so.

  REFRESH: s_size[],
           s_grade[],
           s_ptype[].
  CLEAR: v_init.

  CALL FUNCTION 'GET_GLOBALS_FROM_SLVC_FULLSCR'
    IMPORTING
      e_grid = alv_grid.

  CALL METHOD alv_grid->check_changed_data.
  CALL METHOD alv_grid->refresh_table_display.

  BREAK abap_dev.

  LOOP AT gt_final INTO gs_final WHERE sel EQ 'X'.
    IF v_init IS INITIAL.
      gs_down_so-vbeln    = 'Sales Order No.'.
      gs_down_so-posnr    = 'Item'.
      gs_down_so-werks    = 'Plant'.
      gs_down_so-lgort    = 'Storage Loc.'.
      gs_down_so-matnr    = 'Material Code'.
      gs_down_so-arktx    = 'Mat. Description'.
      gs_down_so-charg    = 'Batch No.'.
      gs_down_so-bal_qty  = 'Bal. Qty'.
      gs_down_so-tol      = 'Toler.'.
      gs_down_so-zzgrade  = 'Grade 1'.
      gs_down_so-zzgrad1  = 'Grade 2'.
      gs_down_so-zzgrad2  = 'Grade 3'.
      gs_down_so-zzsize   = 'Size 1'.
      gs_down_so-zzsiz1   = 'Size 2'.
      gs_down_so-zzsiz2   = 'Size 3'.
      gs_down_so-ptype    = 'Packing Type'.
      gs_down_so-locexp   = 'Loc/Exp'.

      APPEND gs_down_so TO gt_down_so.
      CLEAR: gs_down_so.

      v_init = 'X'.
    ENDIF.

    gs_down_so-vbeln    = gs_final-vbeln.          " Sales Document
    gs_down_so-posnr    = gs_final-posnr.          " Item
    gs_down_so-werks    = gs_final-werks.          " Plant
    gs_down_so-lgort    = gs_final-lgort.          " Stor. Location
    gs_down_so-matnr    = gs_final-matnr.          " Material
    gs_down_so-arktx    = gs_final-arktx.          " Description
    gs_down_so-charg    = gs_final-charg.          " Batch
    gs_down_so-bal_qty  = gs_final-bal_qty.        " Bal. quantity
    gs_down_so-tol      = gs_final-tol_qty.         " Tolerance quantity
    gs_down_so-zzgrade  = gs_final-zzgrade.        " Grade one
    gs_down_so-zzgrad1  = gs_final-zzgrad1.        " Grade two
    gs_down_so-zzgrad2  = gs_final-zzgrad2.        " Grade three
    gs_down_so-zzsize   = gs_final-zzsize.         " Size one
    gs_down_so-zzsiz1   = gs_final-zzsiz1.         " Size two
    gs_down_so-zzsiz2   = gs_final-zzsiz2.         " Size three

    IF gs_final-check EQ 'X'.
      gs_down_so-ptype    = '03'.                    " Pallet Packing Type
    ELSE.
      gs_down_so-ptype    = '01'.                    " Pallet Packing Type
    ENDIF.

    IF gs_down_so-werks = '8001' OR gs_down_so-werks = '8003' .
      gs_down_so-ptype    = '05'.
    ENDIF.

    IF gs_final-vtweg EQ '20'.
      gs_down_so-locexp   = 'E'.
    ELSE.
      gs_down_so-locexp   = 'L'.
    ENDIF.

    IF gs_final-zzsize IS NOT INITIAL.
      s_size-low    = gs_final-zzsize.
      s_size-sign   = 'I'.
      s_size-option = 'EQ'.
      APPEND s_size.
    ENDIF.

    IF gs_final-zzsiz1 IS NOT INITIAL.
      s_size-low    = gs_final-zzsiz1.
      s_size-sign   = 'I'.
      s_size-option = 'EQ'.
      APPEND s_size.
    ENDIF.

    IF gs_final-zzsiz2 IS NOT INITIAL.
      s_size-low    = gs_final-zzsiz2.
      s_size-sign   = 'I'.
      s_size-option = 'EQ'.
      APPEND s_size.
    ENDIF.

    IF gs_final-zzgrade IS NOT INITIAL.
      s_grade-low    = gs_final-zzgrade.
      s_grade-sign   = 'I'.
      s_grade-option = 'EQ'.
      APPEND s_grade.
    ENDIF.

    IF gs_final-zzgrad1 IS NOT INITIAL.
      s_grade-low    = gs_final-zzgrad1.
      s_grade-sign   = 'I'.
      s_grade-option = 'EQ'.
      APPEND s_grade.
    ENDIF.

    IF gs_final-zzgrad2 IS NOT INITIAL.
      s_grade-low    = gs_final-zzgrad2.
      s_grade-sign   = 'I'.
      s_grade-option = 'EQ'.
      APPEND s_grade.
    ENDIF.

    IF gs_down_so-ptype IS NOT INITIAL.
      s_ptype-low    = gs_down_so-ptype.
      s_ptype-sign   = 'I'.
      s_ptype-option = 'EQ'.
      APPEND s_ptype.
    ENDIF.

    APPEND gs_down_so TO gt_down_so.
    CLEAR: gs_down_so.
  ENDLOOP.

  CLEAR: fullpath.

  SELECT SINGLE fpath INTO fullpath
                      FROM zsd_fpath
                      WHERE werks EQ s_vkorg-low AND
                            ud    EQ 'D'.     " Download

  CONCATENATE fullpath '\MKGPL_' sy-datum+6(2) sy-datum+4(2) '_' sy-uzeit(2) '_' sy-uzeit+2(4) '.XLS' INTO fullpath.

  BREAK abap_dev.

  CALL FUNCTION 'GUI_DOWNLOAD'
    EXPORTING
      filename                = fullpath
      filetype                = 'DAT'
    TABLES
      data_tab                = gt_down_so[]
    EXCEPTIONS
      file_write_error        = 1
      no_batch                = 2
      gui_refuse_filetransfer = 3
      invalid_type            = 4
      no_authority            = 5
      unknown_error           = 6
      header_not_allowed      = 7
      separator_not_allowed   = 8
      filesize_not_allowed    = 9
      header_too_long         = 10
      dp_error_create         = 11
      dp_error_send           = 12
      dp_error_write          = 13
      unknown_dp_error        = 14
      access_denied           = 15
      dp_out_of_memory        = 16
      disk_full               = 17
      dp_timeout              = 18
      file_not_found          = 19
      dataprovider_exception  = 20
      control_flush_error     = 21
      OTHERS                  = 22.
  IF sy-subrc <> 0.
* Implement suitable error handling here
    MESSAGE e002(8i) WITH 'Error occured in download file'.
  ENDIF.


ENDFORM.                    " DOWNLOAD_FILE
*&---------------------------------------------------------------------*
*&      Form  GET_BOX_DATA
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM get_box_data .
  PERFORM get_data.
  PERFORM process_data_boxes.
  PERFORM jumbo_pallet.
  PERFORM general_process.
ENDFORM.                    " GET_BOX_DATA
*&---------------------------------------------------------------------*
*&      Form  GET_DATA
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM get_data .

  CLEAR: wa_vepo, it_vepo[],
             wa_vekp, it_vekp[],
                      jt_vekp[],
             wa_pack, it_pack[].

  gt_sfinal[] = gt_final[].

  IF p_chk IS INITIAL.

    DELETE gt_sfinal WHERE sel IS INITIAL.
  ELSE.

  ENDIF.

  IF p_chk IS INITIAL.
*   AND THE REAL CAUSE WAS AN UNGUARDED FOR ALL ENTRIES (03.09.2026).
*
*   The VEKP join below was added first and was NOT enough: KSQ still read
*   26,958,241 rows and dumped in the same place. SY-DBCNT in that dump is
*   what gave it away - that is not "a wide selection", that is the whole
*   of VEPO.
*
*   FOR ALL ENTRIES OVER AN EMPTY DRIVER TABLE DOES NOT SELECT NOTHING.
*   IT DROPS THE WHERE CLAUSE AND SELECTS EVERYTHING. GT_SFINAL is
*   GT_FINAL, and GT_FINAL is legitimately empty whenever DATA_RETRIEVAL
*   finds no open items for the order - the main program even tests for
*   it, but only on the P_CHK IS INITIAL path ("No data found"). The
*   OData path calls GET_BOX_DATA unconditionally, so an order with no
*   open items walked straight into a full scan of VEPO joined to MARA.
*   That is why EVERY sales order failed rather than a particular one.
*
*   Each of the three reads below is now guarded. Nothing else about them
*   changes: a non-empty driver table behaves exactly as before.
*
*   The same trap sits twice more in this form - IT_VEPO drives the VEKP
*   read and IT_VEKP drives the ZPP_PACK read - so an empty IT_VEPO would
*   have scanned all of VEKP next, and an empty IT_VEKP all of ZPP_PACK
*   (27,329,939 rows on KSQ). IT_VEKP was already covered by
*   "CHECK: NOT it_vekp[] IS INITIAL"; IT_VEPO was not, and now is.
*
*   VEKP IS JOINED AND FILTERED HERE, NOT AFTER THE FACT (03.09.2026).
*
*   This read had no restriction to the sales order at all: it took every
*   VEPO row matching the order's material / plant / storage location /
*   batch, for all time. On KSQ that filled IT_VEPO to 5,134,860 rows of
*   152 bytes and the work process died with
*   TSV_TNEW_PAGE_ALLOC_FAILED - about 780 MB of session memory - after
*   roughly three minutes. Gateway wrapped it as SQL_CAUGHT_RABAX and the
*   Scan Suite Packing List showed "Could not load this Sales Order" for
*   every order on the system. KSD never showed it because its whole VEPO
*   is 4,166,356 rows, smaller than the result set KSQ was building.
*
*   The two DELETEs a few lines below already throw away every HU that is
*   not VPOBJ 01/12 and STATUS 0020/0030, and IT_VEPO is only ever READ
*   by VENUM for HUs that survive them. Moving those two conditions into
*   the database changes nothing about what this form produces - it just
*   stops the discarded rows being carried into memory first.
*
*   This is a bound, not a tuning knob. Do not "fix" a future memory dump
*   here by raising a quota.
    CHECK gt_sfinal[] IS NOT INITIAL.

    SELECT a~venum a~vepos a~matnr a~charg a~werks a~lgort a~bestq
      b~zzpdtyp b~zzdenir b~zzfilam b~zzluster b~zzcrosec
      b~zztwist b~zzply b~zzquality b~zzshdcd
    INTO TABLE it_vepo
    FROM vepo AS a
    INNER JOIN mara AS b
    ON a~matnr EQ b~matnr
    INNER JOIN vekp AS c
    ON a~venum EQ c~venum
    FOR ALL ENTRIES IN gt_sfinal
    WHERE a~matnr EQ gt_sfinal-matnr AND
          a~werks EQ gt_sfinal-werks AND
          a~lgort EQ gt_sfinal-lgort AND
          a~charg EQ gt_sfinal-charg AND
          ( c~vpobj EQ '01' OR c~vpobj EQ '12' ) AND
          ( c~status EQ '0020' OR c~status EQ '0030' )."AND

  ELSE.

    IF s_so IS NOT INITIAL.
      SELECT *
        FROM zvbap_batch
        INTO TABLE gt_batch
        WHERE vbeln = s_so-low.
    ENDIF.

*   PER ITEM, NOT PER ORDER (06.09.2026). ZVBAP_BATCH is keyed by item and
*   the VA02 batch tab writes it per item, but this loop read GT_SFINAL by
*   VBELN alone, so every batch on the order was looked up with the FIRST
*   item's material, plant and storage location. On a single-material
*   order that is invisible; on a two-material order a batch named on
*   item 20 was searched under item 10's material, found nothing, and the
*   handheld said "0 boxes" for stock that was there. Two changes:
*     1. each batch is matched to ITS item (VBELN + POSNR); a batch whose
*        item is not pending is skipped instead of borrowing another
*        item's data (the old READ also left LS_FINAL holding the previous
*        loop pass's row when it failed);
*     2. an item with no ZVBAP_BATCH row keeps its own VBAP-CHARG, blank
*        included, exactly as it would if no item on the order had one.
*        Before, one assigned batch anywhere on the order silently dropped
*        every other item's boxes, because only GT_BX_BTC was read.
*   ZCL_ZSOL_SO_BOXCHECK - the Packing List's "Why no boxes?" card -
*   applies this per-item rule; report and card now agree.
    LOOP AT gt_batch INTO DATA(gs_batch).

      READ TABLE gt_sfinal INTO DATA(ls_final) WITH KEY vbeln = gs_batch-vbeln
                                                        posnr = gs_batch-posnr.
      CHECK sy-subrc EQ 0.

      gs_bx_btc-vbeln = ls_final-vbeln.
      gs_bx_btc-posnr = ls_final-posnr.
      gs_bx_btc-matnr = ls_final-matnr.
      gs_bx_btc-werks = ls_final-werks.
      gs_bx_btc-lgort = ls_final-lgort.
      gs_bx_btc-charg = gs_batch-charg.
      APPEND gs_bx_btc TO gt_bx_btc.

    ENDLOOP.

    IF gt_bx_btc IS NOT INITIAL.
      LOOP AT gt_sfinal INTO ls_final.
        READ TABLE gt_batch TRANSPORTING NO FIELDS WITH KEY vbeln = ls_final-vbeln
                                                             posnr = ls_final-posnr.
        CHECK sy-subrc NE 0.
        gs_bx_btc-vbeln = ls_final-vbeln.
        gs_bx_btc-posnr = ls_final-posnr.
        gs_bx_btc-matnr = ls_final-matnr.
        gs_bx_btc-werks = ls_final-werks.
        gs_bx_btc-lgort = ls_final-lgort.
        gs_bx_btc-charg = ls_final-charg.
        APPEND gs_bx_btc TO gt_bx_btc.
      ENDLOOP.
    ENDIF.

    IF gt_bx_btc IS NOT INITIAL.
      SELECT a~venum a~vepos a~matnr a~charg a~werks a~lgort a~bestq
        b~zzpdtyp b~zzdenir b~zzfilam b~zzluster b~zzcrosec
        b~zztwist b~zzply b~zzquality b~zzshdcd
      INTO TABLE it_vepo
      FROM vepo AS a
      INNER JOIN mara AS b
      ON a~matnr EQ b~matnr
      INNER JOIN vekp AS c
      ON a~venum EQ c~venum
      FOR ALL ENTRIES IN gt_bx_btc
      WHERE a~matnr EQ gt_bx_btc-matnr AND
            a~werks EQ gt_bx_btc-werks AND
            a~lgort EQ gt_bx_btc-lgort AND
            a~charg EQ gt_bx_btc-charg AND
            ( c~vpobj EQ '01' OR c~vpobj EQ '12' ) AND
            ( c~status EQ '0020' OR c~status EQ '0030' ).
    ELSEIF gt_sfinal[] IS NOT INITIAL.
*     THIS IS THE BRANCH THAT DUMPED ON KSQ. It is reached whenever
*     GT_BX_BTC came out empty - no ZVBAP_BATCH rows for the order - so
*     the batch restriction is absent and the read falls back to
*     GT_SFINAL. With GT_SFINAL empty as well, FOR ALL ENTRIES dropped
*     its WHERE clause and read the entire table. The ELSEIF is the fix;
*     see the block at the head of this form.
      SELECT a~venum a~vepos a~matnr a~charg a~werks a~lgort a~bestq
       b~zzpdtyp b~zzdenir b~zzfilam b~zzluster b~zzcrosec
       b~zztwist b~zzply b~zzquality b~zzshdcd
     INTO TABLE it_vepo
     FROM vepo AS a
     INNER JOIN mara AS b
     ON a~matnr EQ b~matnr
     INNER JOIN vekp AS c
     ON a~venum EQ c~venum
     FOR ALL ENTRIES IN gt_sfinal
     WHERE a~matnr EQ gt_sfinal-matnr AND
           a~werks EQ gt_sfinal-werks AND
           a~lgort EQ gt_sfinal-lgort AND
           a~charg EQ gt_sfinal-charg AND
           ( c~vpobj EQ '01' OR c~vpobj EQ '12' ) AND
           ( c~status EQ '0020' OR c~status EQ '0030' ).
    ENDIF."AND
*        b~zzpdtyp IN s_pdtyp AND
*        b~zzdenir IN s_denir AND
*        b~zzfilam IN s_filam AND
*        b~zzshdcd IN s_shade.

  ENDIF.
*        b~zzpdtyp IN s_pdtyp AND
*        b~zzdenir IN s_denir AND
*        b~zzfilam IN s_filam AND
*        b~zzshdcd IN s_shade.

* IT_VEPO drives the next FOR ALL ENTRIES, so an empty one would read
* the whole of VEKP. Testing the table rather than SY-SUBRC matters: when
* a guard above skips its SELECT entirely, SY-SUBRC still holds whatever
* the previous statement left, and "CHECK: sy-subrc EQ 0" would wave it
* through.
  CHECK it_vepo[] IS NOT INITIAL.

  SORT it_vepo BY venum.

  SELECT venum exidv exidv2 vpobj uevel status FROM vekp
    INTO TABLE it_vekp
    FOR ALL ENTRIES IN it_vepo
    WHERE venum = it_vepo-venum.

  CHECK: sy-subrc EQ 0.

  DELETE it_vekp WHERE ( vpobj NE '01' AND vpobj NE '12' ).

  DELETE it_vekp WHERE ( status NE '0020' AND status NE '0030' ).

  LOOP AT it_vekp INTO wa_vekp.

    CHECK: NOT wa_vekp-uevel IS INITIAL.

    ja_vekp = wa_vekp.
    APPEND ja_vekp TO jt_vekp.

    DELETE it_vekp.

  ENDLOOP.

*    DELETE it_vekp WHERE NOT uevel IS INITIAL.

  CHECK: NOT it_vekp[] IS INITIAL.

  LOOP AT it_vekp INTO wa_vekp.

*    CALL METHOD me->conversion_output
*      IMPORTING
*        e_boxno = wa_vekp-exidv
*      CHANGING
*        c_boxno = wa_vekp-boxno.

    PERFORM conversion_output USING wa_vekp-exidv
                              CHANGING wa_vekp-boxno.

    MODIFY it_vekp FROM wa_vekp TRANSPORTING boxno.

  ENDLOOP.

  IF p_chk IS NOT INITIAL. " Added by Anjali on 26.11.2024 for Iscan
    LOOP AT gt_final INTO gs_final.
      IF gs_final-zzsize IS NOT INITIAL.
        s_size-low    = gs_final-zzsize.
        s_size-sign   = 'I'.
        s_size-option = 'EQ'.
        APPEND s_size.
      ENDIF.

      IF gs_final-zzsiz1 IS NOT INITIAL.
        s_size-low    = gs_final-zzsiz1.
        s_size-sign   = 'I'.
        s_size-option = 'EQ'.
        APPEND s_size.
      ENDIF.

      IF gs_final-zzsiz2 IS NOT INITIAL.
        s_size-low    = gs_final-zzsiz2.
        s_size-sign   = 'I'.
        s_size-option = 'EQ'.
        APPEND s_size.
      ENDIF.

      IF gs_final-zzgrade IS NOT INITIAL.
        s_grade-low    = gs_final-zzgrade.
        s_grade-sign   = 'I'.
        s_grade-option = 'EQ'.
        APPEND s_grade.
      ENDIF.

      IF gs_final-zzgrad1 IS NOT INITIAL.
        s_grade-low    = gs_final-zzgrad1.
        s_grade-sign   = 'I'.
        s_grade-option = 'EQ'.
        APPEND s_grade.
      ENDIF.

      IF gs_final-zzgrad2 IS NOT INITIAL.
        s_grade-low    = gs_final-zzgrad2.
        s_grade-sign   = 'I'.
        s_grade-option = 'EQ'.
        APPEND s_grade.
      ENDIF.
    ENDLOOP.
  ENDIF.  " Added by Anjali 26.11.2024

  SELECT * FROM zpp_pack INTO TABLE it_pack
    FOR ALL ENTRIES IN it_vekp
    WHERE boxno = it_vekp-boxno AND
          psize IN s_size       AND
          grade IN s_grade      AND
          ptype IN s_ptype.

ENDFORM.                    " GET_DATA
*&---------------------------------------------------------------------*
*&      Form  PROCESS_DATA_BOXES
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM process_data_boxes .
  CHECK: NOT it_pack[] IS INITIAL.

  DELETE it_pack WHERE hupost IS INITIAL AND
                       repack IS INITIAL.

  CLEAR: wa_makt, it_makt[].

  SORT it_pack BY boxno.
  SORT it_vepo BY venum.
  SORT it_vekp BY boxno.

  LOOP AT it_pack INTO wa_pack.

    wa_tab-boxno  = wa_pack-boxno.
    wa_tab-werks  = wa_pack-werks.
    wa_tab-matnr  = wa_pack-matnr.
    wa_tab-mergno = wa_pack-mergno.
    wa_tab-grade  = wa_pack-grade.
    wa_tab-enduse = wa_pack-enduse.
    wa_tab-tpm    = wa_pack-tpm.
    wa_tab-psize  = wa_pack-psize.

    wa_tab-auart  = wa_pack-auart.
    wa_tab-aufnr  = wa_pack-aufnr.
    wa_tab-pdate  = wa_pack-pdate.
    wa_tab-arbpl  = wa_pack-arbpl.


    wa_tab-grosswt = wa_pack-grosswt.
    wa_tab-netwt   = wa_pack-netwt.
    wa_tab-tarewt  = wa_pack-tarewt.
    wa_tab-spoolno = wa_pack-spoolno.
    wa_tab-ptype   = wa_pack-ptype.
    wa_tab-partno  = wa_pack-partno.
    wa_tab-carwt   = wa_pack-carwt.
    wa_tab-kitwt   = wa_pack-kitwt.
    wa_tab-pltyp   = wa_pack-pltyp.
    wa_tab-troll   = wa_pack-troll.

    IF wa_pack-locexp = 'E'.
      wa_tab-locexp = 'Export'.
    ELSEIF wa_pack-locexp = 'L'.
      wa_tab-locexp = 'Local'.
    ELSEIF wa_pack-locexp = 'M'.
      wa_tab-locexp = 'Merchant Export'.    "Added by haresh on 05.01.2012
    ENDIF.

    READ TABLE it_vekp INTO wa_vekp
      WITH KEY boxno = wa_pack-boxno BINARY SEARCH.
    CHECK: sy-subrc EQ 0.


    READ TABLE it_vepo INTO wa_vepo
      WITH KEY venum = wa_vekp-venum BINARY SEARCH.
    CHECK: sy-subrc EQ 0.

    wa_tab-lgort = wa_vepo-lgort.
    wa_tab-pdtyp = wa_vepo-zzpdtyp.
    wa_tab-denir = wa_vepo-zzdenir.
    wa_tab-filam = wa_vepo-zzfilam.
    wa_tab-shdcd = wa_vepo-zzshdcd.
    wa_tab-twist = wa_vepo-zztwist.
    wa_tab-luster = wa_vepo-zzluster.
    wa_tab-quality = wa_vepo-zzquality.
    wa_tab-ply   = wa_vepo-zzply.
    wa_tab-exidv2 = wa_vekp-exidv2.

    IF NOT wa_pack-vbeln IS INITIAL.
      wa_tab-assign = 'YES'.
    ELSEIF wa_vekp-vpobj = '01'.
      wa_tab-assign = 'YES'.
    ELSE.
      wa_tab-assign = 'NO'.
    ENDIF.

    wa_tab-bestq = wa_vepo-bestq.

    APPEND wa_tab TO it_tab.

    wa_makt-matnr = wa_tab-matnr.
    COLLECT wa_makt INTO it_makt.

  ENDLOOP.
ENDFORM.                    " PROCESS_DATA_BOXES
*&---------------------------------------------------------------------*
*&      Form  JUMBO_PALLET
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM jumbo_pallet .
  CHECK: NOT jt_vekp[] IS INITIAL.

  CLEAR: it_pack[], wa_pack,
         it_vekp[], wa_vekp.

  SELECT venum exidv exidv2 vpobj uevel status FROM vekp
    INTO TABLE it_vekp
    FOR ALL ENTRIES IN jt_vekp
    WHERE venum = jt_vekp-uevel.

  CHECK: sy-subrc EQ 0.

  DELETE it_vekp WHERE ( vpobj NE '01' AND vpobj NE '12' ).

  DELETE it_vekp WHERE ( status NE '0020' AND status NE '0030' ).

  LOOP AT it_vekp INTO wa_vekp.

*    CALL METHOD me->conversion_output
*      IMPORTING
*        e_boxno = wa_vekp-exidv
*      CHANGING
*        c_boxno = wa_vekp-boxno.

    PERFORM conversion_output USING wa_vekp-exidv
                              CHANGING wa_vekp-boxno.
    MODIFY it_vekp FROM wa_vekp TRANSPORTING boxno.

  ENDLOOP.


  SELECT * FROM zpp_pack INTO TABLE it_pack
    FOR ALL ENTRIES IN it_vekp
    WHERE boxno = it_vekp-boxno AND
          psize IN s_size       AND
          grade IN s_grade      AND
          ptype IN s_ptype.

  CHECK: NOT it_pack[] IS INITIAL.

  DELETE it_pack WHERE hupost IS INITIAL AND
                       repack IS INITIAL.

  SORT it_pack BY boxno.
  SORT it_vepo BY venum.
  SORT jt_vekp BY uevel.
  SORT it_vekp BY venum.

  LOOP AT it_pack INTO wa_pack.

    wa_tab-boxno  = wa_pack-boxno.
    wa_tab-werks  = wa_pack-werks.
    wa_tab-matnr  = wa_pack-matnr.
    wa_tab-mergno = wa_pack-mergno.
    wa_tab-grade  = wa_pack-grade.
    wa_tab-enduse = wa_pack-enduse.
    wa_tab-tpm    = wa_pack-tpm.
    wa_tab-psize  = wa_pack-psize.

    wa_tab-aufnr  = wa_pack-aufnr.
    wa_tab-auart  = wa_pack-auart.
    wa_tab-pdate  = wa_pack-pdate.
    wa_tab-arbpl  = wa_pack-arbpl.


    wa_tab-grosswt = wa_pack-grosswt.
    wa_tab-netwt   = wa_pack-netwt.
    wa_tab-tarewt  = wa_pack-tarewt.
    wa_tab-spoolno = wa_pack-spoolno.
    wa_tab-ptype   = wa_pack-ptype.
    wa_tab-partno  = wa_pack-partno.
    wa_tab-carwt   = wa_pack-carwt.
    wa_tab-kitwt   = wa_pack-kitwt.
    wa_tab-pltyp   = wa_pack-pltyp.
    wa_tab-troll   = wa_pack-troll.

    IF wa_pack-locexp = 'E'.
      wa_tab-locexp = 'Export'.
    ELSEIF wa_pack-locexp = 'L'.
      wa_tab-locexp = 'Local'.
    ELSEIF wa_pack-locexp = 'M'.
      wa_tab-locexp = 'Merchant Export'.      "Added by haresh 05.01.2012
    ENDIF.

    BREAK abap_dev.

    READ TABLE it_vekp INTO wa_vekp
      WITH KEY boxno = wa_pack-boxno BINARY SEARCH.
    CHECK: sy-subrc EQ 0.

    READ TABLE jt_vekp INTO ja_vekp
      WITH KEY uevel = wa_vekp-venum BINARY SEARCH.
    CHECK: sy-subrc EQ 0.

    READ TABLE it_vepo INTO wa_vepo
      WITH KEY venum = ja_vekp-venum BINARY SEARCH.
    CHECK: sy-subrc EQ 0.

    wa_tab-lgort = wa_vepo-lgort.
    wa_tab-pdtyp = wa_vepo-zzpdtyp.
    wa_tab-denir = wa_vepo-zzdenir.
    wa_tab-filam = wa_vepo-zzfilam.
    wa_tab-shdcd = wa_vepo-zzshdcd.
    wa_tab-twist = wa_vepo-zztwist.
    wa_tab-luster = wa_vepo-zzluster.
    wa_tab-quality = wa_vepo-zzquality.
    wa_tab-ply   = wa_vepo-zzply.
    wa_tab-exidv2 = wa_vekp-exidv2.

    IF NOT wa_pack-vbeln IS INITIAL.
      wa_tab-assign = 'YES'.
    ELSEIF wa_vekp-vpobj = '01'.
      wa_tab-assign = 'YES'.
    ELSE.
      wa_tab-assign = 'NO'.
    ENDIF.

    wa_tab-bestq = wa_vepo-bestq.

    APPEND wa_tab TO it_tab.

    wa_makt-matnr = wa_tab-matnr.
    COLLECT wa_makt INTO it_makt.

  ENDLOOP.

ENDFORM.                    " JUMBO_PALLET
*&---------------------------------------------------------------------*
*&      Form  GENERAL_PROCESS
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM general_process .
  IF NOT it_makt[] IS INITIAL.

    SELECT matnr maktx FROM makt INTO TABLE it_makt
      FOR ALL ENTRIES IN it_makt
      WHERE matnr = it_makt-matnr.
  ENDIF.

  SELECT * FROM zpp_grade INTO TABLE it_grade.

  SELECT * FROM zpp_end INTO TABLE it_euse.

  SELECT * FROM zmm_shade INTO TABLE it_shade.

  SELECT * FROM zpp_ptyp INTO TABLE it_ptype.
  IF NOT it_tab IS INITIAL.
    SELECT * FROM zpp_batch
        INTO TABLE it_zpp_batch
        FOR ALL ENTRIES IN it_tab
        WHERE batchno = it_tab-mergno.

    IF NOT it_zpp_batch IS INITIAL.
      SELECT * FROM zpp_schedule
          INTO TABLE it_zpp_schedule
          FOR ALL ENTRIES IN it_zpp_batch
          WHERE schno = it_zpp_batch-schno.

      IF NOT it_zpp_schedule IS INITIAL.

        SELECT * FROM zpp_shade
            INTO TABLE it_zpp_shade
            FOR ALL ENTRIES IN it_zpp_schedule
            WHERE shdcd = it_zpp_schedule-shdcd.

      ENDIF.
    ENDIF.
  ENDIF.
*    `SELECT * FROM zpp_shade INTO TABLE it_zpp_shade.

  SORT it_makt BY matnr.
  SORT it_shade BY shdcd.
  SORT it_ptype BY ptype.
  SORT it_grade BY gcode.
  SORT it_euse  BY enduse.
  SORT it_zpp_shade BY shdcd.

  LOOP AT it_tab INTO wa_tab.

    READ TABLE it_makt INTO wa_makt
      WITH KEY matnr = wa_tab-matnr BINARY SEARCH.
    IF sy-subrc EQ 0.
      wa_tab-maktx = wa_makt-maktx.
    ENDIF.

    READ TABLE it_ptype INTO wa_ptype
      WITH KEY ptype = wa_tab-ptype BINARY SEARCH.
    IF sy-subrc EQ 0.
      wa_tab-pkdes = wa_ptype-pkdes.
    ENDIF.

    IF NOT wa_tab-pdtyp IS INITIAL.

      CLEAR: wa_domn.
      wa_domn-domname    = 'ZDO_PDTYP'.
      wa_domn-domvalue_l = wa_tab-pdtyp.

      CALL FUNCTION 'DOMAIN_VALUE_GET'
        EXPORTING
          i_domname  = wa_domn-domname
          i_domvalue = wa_domn-domvalue_l
        IMPORTING
          e_ddtext   = wa_domn-ddtext
        EXCEPTIONS
          not_exist  = 1
          OTHERS     = 2.

      wa_tab-pdtxt = wa_domn-ddtext.
    ENDIF.

    READ TABLE it_grade INTO wa_grade
      WITH KEY gcode  = wa_tab-grade
               auart = wa_tab-auart.
    IF sy-subrc EQ 0.
      wa_tab-gdesc = wa_grade-gdesc.
    ENDIF.

    READ TABLE it_euse INTO wa_euse
      WITH KEY enduse = wa_tab-enduse BINARY SEARCH.
    IF sy-subrc EQ 0.
      wa_tab-dustxt = wa_euse-endes.
    ENDIF.

    IF NOT wa_tab-luster IS INITIAL.

      CLEAR: wa_domn.
      wa_domn-domname    = 'ZZDO_LUSTER'.
      wa_domn-domvalue_l = wa_tab-luster.

      CALL FUNCTION 'DOMAIN_VALUE_GET'
        EXPORTING
          i_domname  = wa_domn-domname
          i_domvalue = wa_domn-domvalue_l
        IMPORTING
          e_ddtext   = wa_domn-ddtext
        EXCEPTIONS
          not_exist  = 1
          OTHERS     = 2.

      wa_tab-lustxt = wa_domn-ddtext.
    ENDIF.

    IF NOT wa_tab-twist IS INITIAL.

      CLEAR: wa_domn.
      wa_domn-domname    = 'ZZDO_TWIST'.
      wa_domn-domvalue_l = wa_tab-twist.

      CALL FUNCTION 'DOMAIN_VALUE_GET'
        EXPORTING
          i_domname  = wa_domn-domname
          i_domvalue = wa_domn-domvalue_l
        IMPORTING
          e_ddtext   = wa_domn-ddtext
        EXCEPTIONS
          not_exist  = 1
          OTHERS     = 2.

      wa_tab-twitxt = wa_domn-ddtext.
    ENDIF.

    READ TABLE it_zpp_batch INTO wa_zpp_batch
            WITH KEY batchno = wa_tab-mergno.
    IF wa_zpp_batch IS NOT INITIAL.
      READ TABLE it_zpp_schedule INTO wa_zpp_schedule
              WITH KEY schno = wa_zpp_batch-schno.
      IF sy-subrc = 0.
        READ TABLE it_zpp_shade INTO wa_zpp_shade
                WITH KEY shdcd = wa_zpp_schedule-shdcd.
        IF sy-subrc = 0.
          wa_tab-shdcd = wa_zpp_shade-shdcd.
          wa_tab-descr = wa_zpp_shade-descr.
        ENDIF.
      ENDIF.

    ENDIF.



*      IF NOT wa_tab-shdcd IS INITIAL.
*
**        READ TABLE it_shade INTO wa_shade
**          WITH KEY shdcd = wa_tab-shdcd BINARY SEARCH.
**        IF sy-subrc EQ 0.
**          wa_tab-descr = wa_shade-descr.
**        ENDIF.
*
*      ENDIF.

    IF NOT wa_tab-quality IS INITIAL.

      CLEAR: wa_domn.
      wa_domn-domname    = 'ZZDO_QUALITY'.
      wa_domn-domvalue_l = wa_tab-quality.

      CALL FUNCTION 'DOMAIN_VALUE_GET'
        EXPORTING
          i_domname  = wa_domn-domname
          i_domvalue = wa_domn-domvalue_l
        IMPORTING
          e_ddtext   = wa_domn-ddtext
        EXCEPTIONS
          not_exist  = 1
          OTHERS     = 2.

      wa_tab-qlytxt = wa_domn-ddtext.
    ENDIF.

    IF NOT wa_tab-ply IS INITIAL.

      CLEAR: wa_domn.
      wa_domn-domname    = 'ZZDO_PLY'.
      wa_domn-domvalue_l = wa_tab-ply.

      CALL FUNCTION 'DOMAIN_VALUE_GET'
        EXPORTING
          i_domname  = wa_domn-domname
          i_domvalue = wa_domn-domvalue_l
        IMPORTING
          e_ddtext   = wa_domn-ddtext
        EXCEPTIONS
          not_exist  = 1
          OTHERS     = 2.

      wa_tab-plytxt = wa_domn-ddtext.
    ENDIF.

    CLEAR: wa_domn.
    wa_domn-domname    = 'BESTQ'.
    wa_domn-domvalue_l = wa_tab-bestq.

    CALL FUNCTION 'DOMAIN_VALUE_GET'
      EXPORTING
        i_domname  = wa_domn-domname
        i_domvalue = wa_domn-domvalue_l
      IMPORTING
        e_ddtext   = wa_domn-ddtext
      EXCEPTIONS
        not_exist  = 1
        OTHERS     = 2.

    wa_tab-bestx = wa_domn-ddtext.

    MODIFY it_tab FROM wa_tab.

  ENDLOOP.
  BREAK abap_dev.
  DELETE it_tab[] WHERE assign EQ 'YES'.
ENDFORM.                    " GENERAL_PROCESS
*&---------------------------------------------------------------------*
*&      Form  conversion_output
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM conversion_output USING e_boxno TYPE vekp-exidv
                       CHANGING c_boxno TYPE zpp_pack-boxno.

  CALL FUNCTION 'CONVERSION_EXIT_ALPHA_OUTPUT'
    EXPORTING
      input  = e_boxno
    IMPORTING
      output = c_boxno.

ENDFORM.                    "conversion_output
*&---------------------------------------------------------------------*
*&      Form  DOWNLOAD_FILE_STOCK
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM download_file_stock .

  IF it_tab[] IS INITIAL.
    MESSAGE i000(8i) WITH 'Stock not found!'.
    LEAVE TO SCREEN 0.
  ENDIF.

  REFRESH: it_down_box.

  LOOP AT it_tab INTO wa_tab.
    AT FIRST.
      wa_down_box-boxno   = 'Box No'.
      wa_down_box-werks   = 'Plant'.
      wa_down_box-lgort   = 'Storage Loc.'.
      wa_down_box-matnr   = 'Materail Code'.
      wa_down_box-maktx   = 'Mat. Description'.
      wa_down_box-mergno  = 'Batch'.
      wa_down_box-grade   = 'Grade'.
      wa_down_box-psize   = 'Size'.
      wa_down_box-ptype   = 'Packing Type'.
      wa_down_box-pdate   = 'Prod. Date'.
      wa_down_box-spoolno = 'No. of Spool'.
      wa_down_box-netwt   = 'Net Weight'.
      wa_down_box-grosswt = 'Gross Weight'.
      wa_down_box-tarewt  = 'Tare Weight'.
      wa_down_box-locexp  = 'Loc/Exp.'.
      wa_down_box-exidv2  = 'Old Box No.'.

      APPEND wa_down_box TO it_down_box.
      CLEAR: wa_down_box.
    ENDAT.

    wa_down_box-boxno   = wa_tab-boxno.
    wa_down_box-werks   = wa_tab-werks.
    wa_down_box-lgort   = wa_tab-lgort.
    wa_down_box-matnr   = wa_tab-matnr.
    wa_down_box-maktx   = wa_tab-maktx.
    wa_down_box-mergno  = wa_tab-mergno.
    wa_down_box-grade   = wa_tab-grade.
    wa_down_box-psize   = wa_tab-psize.
    wa_down_box-ptype   = wa_tab-ptype.
*    wa_down_box-pdate   = wa_tab-pdate.
    WRITE: wa_tab-pdate TO wa_down_box-pdate DD/MM/YYYY.
    wa_down_box-spoolno = wa_tab-spoolno.
    wa_down_box-netwt   = wa_tab-netwt.
    wa_down_box-grosswt = wa_tab-grosswt.
    wa_down_box-tarewt  = wa_tab-tarewt.
    wa_down_box-locexp  = wa_tab-locexp.
    wa_down_box-exidv2  = wa_tab-exidv2.

    APPEND wa_down_box TO it_down_box.
    CLEAR: wa_down_box.
  ENDLOOP.

  CLEAR: fullpath.

  SELECT SINGLE fpath INTO fullpath
                      FROM zsd_fpath
                      WHERE werks EQ s_vkorg-low AND
                            ud    EQ 'D'.   " Download

*  CONCATENATE fullpath '\M_KGPL' sy-datum+6(2) sy-datum+4(2) '_' sy-uzeit(4) '.XLS' INTO fullpath.
  CONCATENATE fullpath '\SKGPL_' sy-datum+6(2) sy-datum+4(2) '_' sy-uzeit(2) '_' sy-uzeit+2(4) '.XLS' INTO fullpath.
  CALL FUNCTION 'GUI_DOWNLOAD'
    EXPORTING
      filename                = fullpath
      filetype                = 'DAT'
    TABLES
      data_tab                = it_down_box[]
    EXCEPTIONS
      file_write_error        = 1
      no_batch                = 2
      gui_refuse_filetransfer = 3
      invalid_type            = 4
      no_authority            = 5
      unknown_error           = 6
      header_not_allowed      = 7
      separator_not_allowed   = 8
      filesize_not_allowed    = 9
      header_too_long         = 10
      dp_error_create         = 11
      dp_error_send           = 12
      dp_error_write          = 13
      unknown_dp_error        = 14
      access_denied           = 15
      dp_out_of_memory        = 16
      disk_full               = 17
      dp_timeout              = 18
      file_not_found          = 19
      dataprovider_exception  = 20
      control_flush_error     = 21
      OTHERS                  = 22.
  IF sy-subrc <> 0.
* Implement suitable error handling here
    MESSAGE e002(8i) WITH 'Error occured in download file'.
  ENDIF.
ENDFORM.                    " DOWNLOAD_FILE_STOCK

FORM build_fieldcatalog_hu.


*  LOOP AT it_tab INTO wa_tab.
*    AT FIRST.
*      wa_down_box-boxno   = 'Box No'.
*      wa_down_box-werks   = 'Plant'.
*      wa_down_box-lgort   = 'Storage Loc.'.
*      wa_down_box-matnr   = 'Materail Code'.
*      wa_down_box-maktx   = 'Mat. Description'.
*      wa_down_box-mergno  = 'Batch'.
*      wa_down_box-grade   = 'Grade'.
*      wa_down_box-psize   = 'Size'.
*      wa_down_box-ptype   = 'Packing Type'.
*      wa_down_box-pdate   = 'Prod. Date'.
*      wa_down_box-spoolno = 'No. of Spool'.
*      wa_down_box-netwt   = 'Net Weight'.
*      wa_down_box-grosswt = 'Gross Weight'.
*      wa_down_box-tarewt  = 'Tare Weight'.
*      wa_down_box-locexp  = 'Loc/Exp.'.
*      wa_down_box-exidv2  = 'Old Box No.'.
*
*      APPEND wa_down_box TO it_down_box.
*      CLEAR: wa_down_box.
*    ENDAT.
*
*    wa_down_box-boxno   = wa_tab-boxno.
*    wa_down_box-werks   = wa_tab-werks.
*    wa_down_box-lgort   = wa_tab-lgort.
*    wa_down_box-matnr   = wa_tab-matnr.
*    wa_down_box-maktx   = wa_tab-maktx.
*    wa_down_box-mergno  = wa_tab-mergno.
*    wa_down_box-grade   = wa_tab-grade.
*    wa_down_box-psize   = wa_tab-psize.
*    wa_down_box-ptype   = wa_tab-ptype.
*    WRITE: wa_tab-pdate TO wa_down_box-pdate DD/MM/YYYY.
*    wa_down_box-spoolno = wa_tab-spoolno.
*    wa_down_box-netwt   = wa_tab-netwt.
*    wa_down_box-grosswt = wa_tab-grosswt.
*    wa_down_box-tarewt  = wa_tab-tarewt.
*    wa_down_box-locexp  = wa_tab-locexp.
*    wa_down_box-exidv2  = wa_tab-exidv2.
*
*    APPEND wa_down_box TO it_down_box.
*    CLEAR: wa_down_box.
*
*  ENDLOOP.

  fieldcatalog-fieldname      = 'BOXNO'.
  fieldcatalog-tabname        = 'IT_DOWN_BOX'.
  fieldcatalog-key            = 'X'.
  fieldcatalog-seltext_m      = 'Box no.'.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR fieldcatalog.

  fieldcatalog-fieldname      = 'WERKS'.
  fieldcatalog-tabname        = 'IT_DOWN_BOX'.
  fieldcatalog-key            = 'X'.
  fieldcatalog-seltext_m      = 'Plant'.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR fieldcatalog.

  fieldcatalog-fieldname      = 'LGORT'.
  fieldcatalog-tabname        = 'IT_DOWN_BOX'.
  fieldcatalog-seltext_m      = 'Loc.'.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR fieldcatalog.

  fieldcatalog-fieldname      = 'MATNR'.
  fieldcatalog-tabname        = 'IT_DOWN_BOX'.
  fieldcatalog-checkbox       = 'X'.
  fieldcatalog-seltext_m      = 'Mat. Doc.'.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR fieldcatalog.

  fieldcatalog-fieldname      = 'MAKTX'.
  fieldcatalog-tabname        = 'IT_DOWN_BOX'.
  fieldcatalog-seltext_m      = 'Mat. Desc'.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR fieldcatalog.

  fieldcatalog-fieldname      = 'MERGNO'.
  fieldcatalog-tabname        = 'IT_DOWN_BOX'.
  fieldcatalog-seltext_m      = 'Batch'.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR fieldcatalog.

  fieldcatalog-fieldname      = 'GRADE'.
  fieldcatalog-tabname        = 'IT_DOWN_BOX'.
  fieldcatalog-seltext_m      = 'Grade'.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR fieldcatalog.

  fieldcatalog-fieldname      = 'PSIZE'.
  fieldcatalog-tabname        = 'IT_DOWN_BOX'.
  fieldcatalog-seltext_m      = 'Size'.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR fieldcatalog.

  fieldcatalog-fieldname      = 'PTYPE'.
  fieldcatalog-tabname        = 'IT_DOWN_BOX'.
  fieldcatalog-seltext_m      = 'Pack. Typ'.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR fieldcatalog.

  fieldcatalog-fieldname      = 'PDATE'.
  fieldcatalog-tabname        = 'IT_DOWN_BOX'.
  fieldcatalog-seltext_m      = 'Prod. Date'.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR fieldcatalog.

  fieldcatalog-fieldname      = 'SPOOLNO'.
  fieldcatalog-tabname        = 'IT_DOWN_BOX'.
  fieldcatalog-ref_tabname    = 'VBAK'.
  fieldcatalog-ref_fieldname  = 'VDATU'.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR fieldcatalog.

  fieldcatalog-fieldname      = 'NETWT'.
  fieldcatalog-tabname        = 'IT_DOWN_BOX'.
  fieldcatalog-seltext_m      = 'Net Wt.'.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR fieldcatalog.

  fieldcatalog-fieldname      = 'GROSSWT'.
  fieldcatalog-tabname        = 'IT_DOWN_BOX'.
  fieldcatalog-seltext_m      = 'Gross Wt.'.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR fieldcatalog.

  fieldcatalog-fieldname      = 'TAREWT'.
  fieldcatalog-tabname        = 'IT_DOWN_BOX'.
  fieldcatalog-seltext_m      = 'Tare Wt.'.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR fieldcatalog.

  fieldcatalog-fieldname      = 'LOCEXP'.
  fieldcatalog-tabname        = 'IT_DOWN_BOX'.
  fieldcatalog-seltext_m      = 'Loc./Exp'.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR fieldcatalog.

  fieldcatalog-fieldname      = 'EXIDV2'.
  fieldcatalog-tabname        = 'IT_DOWN_BOX'.
  fieldcatalog-seltext_m      = 'Old Box no.'.
  APPEND fieldcatalog TO fieldcatalog.
  CLEAR fieldcatalog.

ENDFORM.