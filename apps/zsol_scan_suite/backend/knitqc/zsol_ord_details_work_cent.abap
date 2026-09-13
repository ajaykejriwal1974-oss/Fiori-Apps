*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*& Include ZSOL_ORD_DETAILS_WORK_CENT
*&---------------------------------------------------------------------*

*&---------------------------------------------------------------------*
*& Form get_oder_details
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*

DATA: vlines       TYPE i,
      msg          TYPE string,
      lv_text01(8) ,
      lv_wc(8) ,
      lv_ms5       TYPE string,
      lv_text02(3) .

* Knitting roll QC hold (06.09.2026, ZCL_ZKNIT_ROLL_QC). See FORM
* KNIT_QC_CHECK below.
DATA: gv_kqc_block  TYPE abap_bool,
      gv_kqc_msg    TYPE string,
      gv_kqc_dqc    TYPE c LENGTH 1,
      gv_kqc_grade  TYPE zde_gcode.

MODULE validate_arbpl01 INPUT.
  CHECK: NOT wa_tab-arbpl IS INITIAL AND
         v_repack EQ 'Y'.

  SELECT SINGLE * FROM crhd
    WHERE werks = wa_tab-werks AND
          arbpl = wa_tab-arbpl.
  IF sy-subrc NE 0.
    MESSAGE e002(sy) WITH 'Invalid Work Center'.
  ENDIF.
ENDMODULE.


FORM get_order_details .
  IF sy-tcode EQ 'ZPACK01' .

    IF wa_tab-arbpl IS NOT INITIAL AND wa_tab-zmrno IS NOT INITIAL .
*    CLEAR: wa_tab-arbpl .
      SPLIT wa_tab-zmrno AT '/' INTO lv_text01 lv_wc .

      SELECT * FROM zsolopenord INTO TABLE it_ord01 WHERE arbpl EQ lv_text01.
      DESCRIBE TABLE it_ord01 LINES vlines .
      IF vlines GT '1'.
        CONCATENATE  'There are multiple Open order numbers for work center' lv_text01
                      INTO msg SEPARATED BY space .
        MESSAGE : msg TYPE 'E' .

      ELSEIF vlines EQ '1'.
        READ TABLE it_ord01 INTO wa_ord01 INDEX 01 .
        IF wa_tab-aufnr NE wa_ord01-aufnr.
          MESSAGE : 'This Rolls belongs to a different Work Center. Data will be reset.'
                     TYPE 'I'
                     DISPLAY LIKE 'W' .
          LEAVE TO TRANSACTION 'ZPACK01' .
*        PERFORM clear_screen.
        ENDIF.
      ENDIF.


    ELSEIF wa_tab-arbpl IS NOT INITIAL .
      SELECT * FROM zsolopenord INTO TABLE it_ord01 WHERE arbpl EQ wa_tab-arbpl.
      DESCRIBE TABLE it_ord01 LINES vlines .
      IF vlines GT '1'.
        CONCATENATE  'There are multiple Open order numbers for work center' wa_tab-arbpl
                      INTO msg SEPARATED BY space .
        MESSAGE : msg TYPE 'E' .
      ELSEIF vlines EQ '1'.
        READ TABLE it_ord01 INTO wa_ord01 INDEX 01 .
        IF sy-subrc = 0.
          wa_tab-aufnr = wa_ord01-aufnr .
        ENDIF.
      ENDIF.

    ELSEIF wa_tab-zmrno IS NOT INITIAL .

      SPLIT wa_tab-zmrno AT '/' INTO lv_text01 lv_wc .

      SELECT * FROM zsolopenord INTO TABLE it_ord01 WHERE arbpl EQ lv_text01.
      IF sy-subrc = 0.
        SELECT SINGLE * FROM zroll INTO @DATA(ls_data)
           WHERE werks = @wa_tab-werks
           AND arbpl = @lv_text01
              AND f_mrno <= @lv_wc
              AND t_mrno >= @lv_wc.
      ENDIF.
      DESCRIBE TABLE it_ord01 LINES vlines .
      IF vlines GT '1'.
        CLEAR: msg.
        CONCATENATE  'There are multiple Open order numbers for work center' lv_text01
                      INTO msg SEPARATED BY space .
        MESSAGE : msg TYPE 'E' .
      ELSEIF vlines EQ '1'.
        READ TABLE it_ord01 INTO wa_ord01 INDEX 01 .
        IF sy-subrc = 0.
          IF ls_data IS NOT INITIAL AND ls_data-aufnr NE wa_ord01-aufnr.
            CALL FUNCTION 'CONVERSION_EXIT_ALPHA_OUTPUT'
              EXPORTING
                input         =  ls_data-aufnr
             IMPORTING
               OUTPUT        = ls_data-aufnr.
            CONCATENATE 'This Rol belongs to 'ls_data-aufnr'Production order, Data will be reset.' INTO lv_ms5 SEPARATED BY space.
            MESSAGE : lv_ms5
            TYPE 'I'
            DISPLAY LIKE 'W' .
            LEAVE TO TRANSACTION 'ZPACK01'.
          ELSE.
            wa_tab-aufnr = wa_ord01-aufnr .
            wa_tab-arbpl = wa_ord01-arbpl .
          ENDIF.
        ENDIF.
      ENDIF.
    ELSE.
      MESSAGE i002(sy) WITH 'Please enter Order Number OR Work Center OR MR No.'  .
    ENDIF.
    SELECT SINGLE * FROM aufk
      WHERE aufnr EQ wa_tab-aufnr AND
            werks EQ wa_tab-werks.
    wa_tab-auart =  aufk-auart.
    IF sy-subrc NE 0.
      MESSAGE i002(sy) WITH 'Invalid Order'.
      LEAVE TO SCREEN sy-dynnr.
    ELSEIF wa_tab-auart NE aufk-auart.
      MESSAGE i002(sy) WITH 'Order Type mismatch'.
      LEAVE TO SCREEN sy-dynnr.
    ELSE.
      SELECT SINGLE * FROM zpp_mpck
        WHERE werks EQ wa_tab-werks AND
              auart EQ wa_tab-auart.
      IF sy-subrc NE 0.
        CONCATENATE 'Invalid Order Type' wa_tab-auart 'for plant'
          wa_tab-werks INTO v_msgtxt SEPARATED BY space.
        MESSAGE i002(sy) WITH v_msgtxt.
        LEAVE TO SCREEN sy-dynnr.
      ENDIF.
    ENDIF.

    IF NOT wa_tab-auart IS INITIAL.
      SELECT SINGLE txt FROM t003p INTO wa_tab-txt
        WHERE spras EQ sy-langu AND
              auart EQ wa_tab-auart.
    ENDIF.

*  TABLES : zpack_mast.
    CLEAR: wa_tab-matnr,
           wa_tab-fgtpm,
           wa_tab-zzpdtyp,
           wa_tab-maktx.
*         wa_tab-arbpl.

*  CLEAR: wa_tabl, it_tabl[].

    CHECK: NOT wa_tab-aufnr IS INITIAL.

    wa_tc = 'XXXX'.

    CLEAR: it_afvc[], wa_afvc,
           it_crhd[], wa_crhd.

    SELECT SINGLE * FROM aufk
      WHERE aufnr EQ wa_tab-aufnr AND
            werks EQ wa_tab-werks.
    IF sy-subrc NE 0.
      MESSAGE e002(sy) WITH 'Invalid Order'.
*  ELSEIF wa_tab-auart NE aufk-auart.
*    MESSAGE e002(sy) WITH 'Order Type mismatch'.
    ELSE.
      SELECT SINGLE auart
                 FROM aufk
                 INTO wa_tab-auart
                 WHERE aufnr EQ wa_tab-aufnr.
      IF NOT wa_tab-auart IS INITIAL.

        SELECT SINGLE txt FROM t003p INTO wa_tab-txt
          WHERE spras EQ sy-langu AND
                auart EQ wa_tab-auart.
      ENDIF.
      SELECT SINGLE matnr lgort FROM afpo
        INTO (wa_tab-matnr, wa_tab-lgort)
        WHERE aufnr = wa_tab-aufnr.
      IF NOT wa_tab-matnr IS INITIAL.

        SELECT SINGLE maktx FROM makt INTO wa_tab-maktx
          WHERE matnr = wa_tab-matnr AND
                spras = sy-langu.

        SELECT SINGLE zzpdtyp FROM mara INTO wa_tab-zzpdtyp
          WHERE matnr = wa_tab-matnr.
        IF sy-subrc EQ 0 AND
         ( wa_tab-zzpdtyp = 'Y' OR wa_tab-zzpdtyp = 'Q' OR
           wa_tab-zzpdtyp = 'Z' ).
          wa_tab-fgtpm = 'X'.
        ENDIF.

      ENDIF.

      SELECT SINGLE * FROM zpp_mpck
        WHERE werks EQ wa_tab-werks AND
              auart EQ wa_tab-auart.
      IF sy-subrc NE 0.
        CONCATENATE 'Invalid Order Type' wa_tab-auart 'for plant'
          wa_tab-werks INTO v_msgtxt SEPARATED BY space.
        MESSAGE e002(sy) WITH v_msgtxt.
      ENDIF.
    ENDIF.

    IF wa_tab-werks NE '1000' AND wa_tab-werks NE '1001' AND wa_tab-werks   = '1002'. "Added by Hiren 03.07.2019".

      wa_tabl-paper = aufk-zzpr1.
      wa_tabl-weigt = aufk-zzwg1.
      wa_tabl-meins = aufk-zzme1.
      wa_tabl-menge = aufk-zzwg1.


      IF NOT wa_tabl-paper IS INITIAL.
        SELECT SINGLE maktx FROM makt INTO wa_tabl-maktx
          WHERE matnr = wa_tabl-paper.
      ENDIF.
      APPEND wa_tabl TO it_tabl.
      CLEAR: wa_tabl.

      wa_tabl-paper = aufk-zzpr2.
      wa_tabl-weigt = aufk-zzwg2.
      wa_tabl-meins = aufk-zzme2.

      IF NOT wa_tabl-paper IS INITIAL.
        SELECT SINGLE maktx FROM makt INTO wa_tabl-maktx
          WHERE matnr = wa_tabl-paper.
      ENDIF.

      APPEND wa_tabl TO it_tabl.
      CLEAR: wa_tabl.

      wa_tabl-paper = aufk-zzpr3.
      wa_tabl-weigt = aufk-zzwg3.
      wa_tabl-meins = aufk-zzme3.

      IF NOT wa_tabl-paper IS INITIAL.
        SELECT SINGLE maktx FROM makt INTO wa_tabl-maktx
          WHERE matnr = wa_tabl-paper.
      ENDIF.

      APPEND wa_tabl TO it_tabl.
      CLEAR: wa_tabl.

      wa_tabl-paper = aufk-zzpr4.
      wa_tabl-weigt = aufk-zzwg4.
      wa_tabl-meins = aufk-zzme4.

      IF NOT wa_tabl-paper IS INITIAL.
        SELECT SINGLE maktx FROM makt INTO wa_tabl-maktx
          WHERE matnr = wa_tabl-paper.
      ENDIF.

      APPEND wa_tabl TO it_tabl.
      CLEAR: wa_tabl.

    ENDIF.

*   Knitting roll QC hold (06.09.2026). GET_ORDER_DETAILS runs on every
*   Enter and again from VALIDATE_DATA before the posting, so the check
*   here is the one that sees the grade the operator finally chose. A
*   roll under Dyeing QC, or a failed roll being packed as 1ST, stops
*   the posting.
    IF wa_tab-zmrno IS NOT INITIAL.
      PERFORM knit_qc_check USING 'X'.
    ENDIF.

  ENDIF.
*  PERFORM check_mandatory_fields.


ENDFORM.


*&---------------------------------------------------------------------*
*&      Module  VALIDATE_ARBPL01  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Module  VALIDATE_MRNO  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE validate_mrno INPUT.
  IF sy-tcode EQ 'ZPACK01'.
    IF wa_tab-zmrno IS NOT INITIAL.
      SELECT SINGLE zmrno FROM zpp_pack INTO @DATA(l_mrno) WHERE zmrno EQ @wa_tab-zmrno.
      IF l_mrno IS NOT INITIAL.

        CONCATENATE  'MRNO' l_mrno 'is already exist.'
                      INTO er_msg SEPARATED BY space .
        MESSAGE : er_msg TYPE 'E' ."DISPLAY LIKE 'I'.
      ENDIF.

*     Knitting roll QC hold (06.09.2026): the roll's own field is where
*     the operator learns that it must not be packed. The grade is not
*     typed yet at this point, so a failed dyeing result only defaults
*     the grade down here and becomes an error in KNIT_QC_CHECK at post
*     time if 1ST is still chosen.
      PERFORM knit_qc_check USING space.
    ENDIF.
  ENDIF.
ENDMODULE.


*&---------------------------------------------------------------------*
*&      Form  KNIT_QC_CHECK
*&---------------------------------------------------------------------*
*  Asks ZCL_ZKNIT_ROLL_QC whether the roll in WA_TAB-ZMRNO may be packed.
*    P_POST = space  called from the MR-number field (PAI module): a hold
*                    is an E message on the field; advice is a status
*                    line; the grade is defaulted from Physical QC.
*    P_POST = 'X'    called before the posting: a hold, or 1ST quality on
*                    a failed roll, stops the posting with a popup.
*  ZREPACK and ZPACK02 never come here (SY-TCODE), so downgrading a
*  failed roll by repacking is untouched.
*----------------------------------------------------------------------*
FORM knit_qc_check USING p_post TYPE c.

  CHECK sy-tcode EQ 'ZPACK01'.
  CHECK wa_tab-zmrno IS NOT INITIAL.

  CLEAR: gv_kqc_block, gv_kqc_msg, gv_kqc_dqc, gv_kqc_grade.

  zcl_zknit_roll_qc=>check_pack( EXPORTING iv_werks      = wa_tab-werks
                                           iv_zmrno      = wa_tab-zmrno
                                           iv_grade      = wa_tab-grade
                                 IMPORTING ev_block      = gv_kqc_block
                                           ev_message    = gv_kqc_msg
                                           ev_dqc_status = gv_kqc_dqc
                                           ev_pqc_grade  = gv_kqc_grade ).

  IF p_post IS INITIAL.
*   On the field: default the grade from Physical QC, one step down when
*   the dyeing sample failed.
    IF wa_tab-grade IS INITIAL AND gv_kqc_grade IS NOT INITIAL.
      wa_tab-grade = gv_kqc_grade.
    ENDIF.
    IF gv_kqc_dqc = zcl_zknit_roll_qc=>gc_dqc_failed AND
       ( wa_tab-grade IS INITIAL OR wa_tab-grade = zcl_zknit_roll_qc=>gc_grade_first ).
      wa_tab-grade = 'B'.
    ENDIF.
    IF gv_kqc_block = abap_true.
      MESSAGE gv_kqc_msg TYPE 'E'.
    ELSEIF gv_kqc_msg IS NOT INITIAL.
      MESSAGE gv_kqc_msg TYPE 'S' DISPLAY LIKE 'W'.
    ENDIF.
  ELSE.
    IF gv_kqc_block = abap_true.
      v_field = 'WA_TAB-ZMRNO'.
      MESSAGE gv_kqc_msg TYPE 'I' DISPLAY LIKE 'E'.
      LEAVE TO SCREEN sy-dynnr.
    ENDIF.
  ENDIF.

ENDFORM.
