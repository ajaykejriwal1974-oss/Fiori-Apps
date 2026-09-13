CLASS zcl_zknit_roll_qc DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

* ----------------------------------------------------------------------
* Knitting roll QC for the Mango Filament knitting plants (company code
* 8000: 8001, 8003). One class holds the rules; the Scan Suite's OData
* service (ZCL_ZSOL_KNIT_QC_DPC) and the packing transaction ZPACK01
* (ZPP_PACK_MODULE_NEW, MODULE VALIDATE_MRNO) both call it, so the two
* cannot disagree about what "on hold" means.
*
* THE ROLL'S IDENTITY IS THE LABEL. ZSBAR prints "MK0013/5443" - knitting
* machine (work centre) and a running number - before the roll exists in
* any table, and ZPACK01 later stores exactly that text in ZPP_PACK-ZMRNO.
* PARSE_MRNO turns a scan into the key (WERKS, ARBPL, MRNO) and back into
* the canonical text, so "mk0013/5443 " and "MK0013/05443" are one roll.
*
* THE ORDER COMES FROM THE PRINT LOG. ZROLL records, per print run, the
* range of roll numbers printed for a work centre and the production
* order open at that moment. That is the same lookup ZPACK01 does
* (ZSOL_ORD_DETAILS_WORK_CENT, FORM GET_ORDER_DETAILS), reused here so QC
* and packing name the same order. When the print run cannot be found the
* open order of the work centre (ZSOLOPENORD) is taken, as ZPACK01 does.
*
* THE HOLD. A roll is not to be packed while its dyeing sample is out
* (status S sent, R received) and never as 1st quality once the sample
* FAILED (status F). CHECK_PACK is the single verdict; ZPACK01 turns it
* into an error on the MR-number field. Repacking (ZREPACK) is deliberately
* not checked: that is how a failed roll is downgraded.
*
* NOTHING HERE POSTS TO SAP STOCK. Physical QC and Dyeing QC are recorded
* in ZKNIT_ROLL_QC only; the goods receipt and the handling unit are still
* made by ZPACK01 when the roll is packed, exactly as before.
* ----------------------------------------------------------------------

  PUBLIC SECTION.

    CONSTANTS:
      gc_dqc_none     TYPE c LENGTH 1 VALUE ' ',
      gc_dqc_sent     TYPE c LENGTH 1 VALUE 'S',
      gc_dqc_received TYPE c LENGTH 1 VALUE 'R',
      gc_dqc_cleared  TYPE c LENGTH 1 VALUE 'C',
      gc_dqc_failed   TYPE c LENGTH 1 VALUE 'F'.

    " Grade code of order type KNT that means 1st quality (ZPP_GRADE).
    CONSTANTS gc_grade_first TYPE zde_gcode VALUE 'A'.

    " Dyeing results normally arrive within this many days; older pending
    " samples are flagged as overdue in the lists.
    CONSTANTS gc_dye_days TYPE i VALUE 2.

    TYPES: BEGIN OF ty_key,
             werks TYPE werks_d,
             arbpl TYPE arbpl,
             mrno  TYPE n LENGTH 6,
             zmrno TYPE zdemrno,
           END OF ty_key.

    " Everything a screen needs about one roll: the label, the order, the
    " two QC verdicts and - if it has been packed - the packing record.
    TYPES: BEGIN OF ty_roll,
             werks         TYPE werks_d,
             arbpl         TYPE arbpl,
             mrno          TYPE n LENGTH 6,
             zmrno         TYPE zdemrno,
             aufnr         TYPE aufnr,
             matnr         TYPE matnr,
             maktx         TYPE maktx,
             print_date    TYPE d,
             pqc_date      TYPE d,
             pqc_time      TYPE t,
             pqc_user      TYPE c LENGTH 40,
             pqc_grade     TYPE zde_gcode,
             pqc_grade_txt TYPE c LENGTH 20,
             pqc_defects   TYPE c LENGTH 60,
             pqc_remark    TYPE c LENGTH 100,
             dqc_status    TYPE c LENGTH 1,
             dqc_sent_date TYPE d,
             dqc_recv_date TYPE d,
             dqc_res_date  TYPE d,
             dqc_res_user  TYPE c LENGTH 40,
             dqc_remark    TYPE c LENGTH 100,
             days_pending  TYPE i,
             hold          TYPE abap_bool,
             pack_boxno    TYPE zpp_pack-boxno,
             pack_grade    TYPE zpp_pack-grade,
             pack_date     TYPE d,
             pack_netwt    TYPE zpp_pack-netwt,
             exists        TYPE abap_bool,
           END OF ty_roll.
    TYPES tt_roll TYPE STANDARD TABLE OF ty_roll WITH EMPTY KEY.

    TYPES: BEGIN OF ty_defect,
             werks    TYPE werks_d,
             dcode    TYPE c LENGTH 4,
             descr    TYPE c LENGTH 40,
             sortno   TYPE n LENGTH 3,
             inactive TYPE c LENGTH 1,
           END OF ty_defect.
    TYPES tt_defect TYPE STANDARD TABLE OF ty_defect WITH EMPTY KEY.

    TYPES: BEGIN OF ty_grade,
             gcode TYPE zde_gcode,
             gdesc TYPE zpp_grade-gdesc,
           END OF ty_grade.
    TYPES tt_grade TYPE STANDARD TABLE OF ty_grade WITH EMPTY KEY.

    TYPES ty_r_werks TYPE RANGE OF werks_d.

    " "MK0013/5443" -> key. Fails (EV_ERROR filled) on anything that is
    " not machine/number.
    CLASS-METHODS parse_mrno
      IMPORTING
        !iv_scan  TYPE clike
        !iv_werks TYPE werks_d OPTIONAL
      EXPORTING
        !es_key   TYPE ty_key
        !ev_error TYPE string.

    " The roll as the screens see it. Resolves order and material from the
    " print log, merges the QC row if there is one, and the packing record
    " if the roll has been packed. IV_WERKS narrows the print-log lookup;
    " when it is not given the plant comes from the print log itself.
    CLASS-METHODS resolve_roll
      IMPORTING
        !iv_scan  TYPE clike
        !iv_werks TYPE werks_d OPTIONAL
      EXPORTING
        !es_roll  TYPE ty_roll
        !ev_error TYPE string.

    " Physical QC. Creates the row on first scan, updates it on a rescan.
    " IV_DYE_SAMPLE = X starts the dyeing-QC hold (status S); un-ticking it
    " on a rescan clears the hold only while the sample has not reached
    " the lab (still S).
    CLASS-METHODS record_physical_qc
      IMPORTING
        !is_key        TYPE ty_key
        !iv_user       TYPE clike
        !iv_grade      TYPE zde_gcode
        !iv_defects    TYPE clike OPTIONAL
        !iv_remark     TYPE clike OPTIONAL
        !iv_dye_sample TYPE abap_bool DEFAULT abap_false
      EXPORTING
        !es_roll       TYPE ty_roll
        !ev_error      TYPE string.

    " The lab confirms the sample arrived (S -> R). A roll nobody ticked at
    " Physical QC can still be received - the lab has the sample in hand.
    CLASS-METHODS record_dye_received
      IMPORTING
        !is_key   TYPE ty_key
        !iv_user  TYPE clike
      EXPORTING
        !es_roll  TYPE ty_roll
        !ev_error TYPE string.

    " The lab's verdict: C cleared, F failed.
    CLASS-METHODS record_dye_result
      IMPORTING
        !is_key    TYPE ty_key
        !iv_user   TYPE clike
        !iv_result TYPE char1
        !iv_remark TYPE clike OPTIONAL
      EXPORTING
        !es_roll   TYPE ty_roll
        !ev_error  TYPE string.

    " The verdict ZPACK01 asks for on the MR-number field.
    "   EV_BLOCK = X   -> refuse (message in EV_MESSAGE)
    "   EV_DQC_STATUS  -> F means: may be packed, but not as 1st quality
    "   EV_PQC_GRADE   -> what Physical QC graded, to default the field
    "   EV_MESSAGE     -> also filled, non-blocking, when there is no
    "                     Physical QC record at all
    CLASS-METHODS check_pack
      IMPORTING
        !iv_werks      TYPE werks_d
        !iv_zmrno      TYPE clike
        !iv_grade      TYPE zde_gcode OPTIONAL
      EXPORTING
        !ev_block      TYPE abap_bool
        !ev_message    TYPE string
        !ev_dqc_status TYPE char1
        !ev_pqc_grade  TYPE zde_gcode.

    " Rolls whose dyeing sample is out or failed - the packing hold list.
    CLASS-METHODS get_hold_list
      IMPORTING
        !it_werks       TYPE ty_r_werks OPTIONAL
      RETURNING
        VALUE(rt_rolls) TYPE tt_roll.

    " Rolls waiting for a dyeing result (S, R) - the lab's worklist.
    CLASS-METHODS get_pending_dye
      IMPORTING
        !it_werks       TYPE ty_r_werks OPTIONAL
      RETURNING
        VALUE(rt_rolls) TYPE tt_roll.

    " Every roll Physical QC scanned in a date window - the production
    " list. Optional order / machine narrowing.
    CLASS-METHODS get_production
      IMPORTING
        !it_werks       TYPE ty_r_werks OPTIONAL
        !iv_date_from   TYPE d
        !iv_date_to     TYPE d
        !iv_aufnr       TYPE aufnr OPTIONAL
        !iv_arbpl       TYPE arbpl OPTIONAL
      RETURNING
        VALUE(rt_rolls) TYPE tt_roll.

    CLASS-METHODS get_defect_codes
      IMPORTING
        !iv_werks         TYPE werks_d OPTIONAL
      RETURNING
        VALUE(rt_defects) TYPE tt_defect.

    CLASS-METHODS get_grades
      RETURNING
        VALUE(rt_grades) TYPE tt_grade.

  PRIVATE SECTION.

    CONSTANTS gc_auart_knt TYPE aufart VALUE 'KNT'.

    CLASS-METHODS read_row
      IMPORTING
        !is_key       TYPE ty_key
      RETURNING
        VALUE(rs_row) TYPE zknit_roll_qc.

    " ZKNIT_ROLL_QC rows -> screen rows, with texts and packing state.
    CLASS-METHODS rows_to_rolls
      IMPORTING
        !it_rows        TYPE STANDARD TABLE
      RETURNING
        VALUE(rt_rolls) TYPE tt_roll.

    CLASS-METHODS stamp_change
      IMPORTING
        !iv_user TYPE clike
      CHANGING
        !cs_row  TYPE zknit_roll_qc.

    CLASS-METHODS days_since
      IMPORTING
        !iv_date       TYPE d
      RETURNING
        VALUE(rv_days) TYPE i.

ENDCLASS.



CLASS zcl_zknit_roll_qc IMPLEMENTATION.


  METHOD parse_mrno.

    DATA: lv_scan  TYPE string,
          lv_left  TYPE string,
          lv_right TYPE string.

    CLEAR: es_key, ev_error.

    lv_scan = iv_scan.
    CONDENSE lv_scan NO-GAPS.
    TRANSLATE lv_scan TO UPPER CASE.

    IF lv_scan IS INITIAL.
      ev_error = 'Scan the roll label (MR No.)'.
      RETURN.
    ENDIF.

    " Machine and number are separated by '/'. A '-' or a blank in its
    " place is accepted too; nothing else is guessed.
    REPLACE ALL OCCURRENCES OF '-' IN lv_scan WITH '/'.
    SPLIT lv_scan AT '/' INTO lv_left lv_right.

    IF lv_left IS INITIAL OR lv_right IS INITIAL OR lv_right CN '0123456789'.
      ev_error = |{ iv_scan } is not a roll label - expected machine/number, e.g. MK0013/5443|.
      RETURN.
    ENDIF.

    IF strlen( lv_left ) > 8.
      ev_error = |{ lv_left } is not a knitting machine (work centre) code|.
      RETURN.
    ENDIF.
    IF strlen( lv_right ) > 6.
      ev_error = |Roll number { lv_right } is too long|.
      RETURN.
    ENDIF.

    es_key-werks = iv_werks.
    es_key-arbpl = lv_left.
    es_key-mrno  = lv_right.
    " Canonical text: machine, slash, number without leading zeros - the
    " form ZSBAR prints and ZPACK01 stores.
    es_key-zmrno = |{ es_key-arbpl }/{ es_key-mrno ALPHA = OUT }|.
    CONDENSE es_key-zmrno NO-GAPS.

  ENDMETHOD.


  METHOD resolve_roll.

    DATA: ls_key  TYPE ty_key,
          ls_row  TYPE zknit_roll_qc,
          lt_rows TYPE STANDARD TABLE OF zknit_roll_qc WITH EMPTY KEY,
          lt_out  TYPE tt_roll,
          lv_mrno TYPE i.

    CLEAR: es_roll, ev_error.

    parse_mrno( EXPORTING iv_scan = iv_scan iv_werks = iv_werks
                IMPORTING es_key = ls_key ev_error = ev_error ).
    IF ev_error IS NOT INITIAL.
      RETURN.
    ENDIF.

    lv_mrno = ls_key-mrno.

    " 1. The print run that produced this label: work centre and roll
    "    number inside the printed range. The newest run wins when ranges
    "    overlap (ZSBAR restarts numbering when the date changes).
    IF ls_key-werks IS NOT INITIAL.
      SELECT werks, arbpl, aufnr, pdate
        FROM zroll
        WHERE werks  = @ls_key-werks
          AND arbpl  = @ls_key-arbpl
          AND f_mrno <= @lv_mrno
          AND t_mrno >= @lv_mrno
        ORDER BY pdate DESCENDING, srno DESCENDING
        INTO TABLE @DATA(lt_print)
        UP TO 1 ROWS.
    ELSE.
      SELECT werks, arbpl, aufnr, pdate
        FROM zroll
        WHERE arbpl  = @ls_key-arbpl
          AND f_mrno <= @lv_mrno
          AND t_mrno >= @lv_mrno
        ORDER BY pdate DESCENDING, srno DESCENDING
        INTO TABLE @lt_print
        UP TO 1 ROWS.
    ENDIF.

    " 2. An existing QC row - it already knows plant and order.
    IF lt_print IS NOT INITIAL.
      ls_key-werks = lt_print[ 1 ]-werks.
    ENDIF.
    IF ls_key-werks IS NOT INITIAL.
      ls_row = read_row( ls_key ).
    ELSE.
      " No plant from the caller and no print run: the QC row, if any,
      " is the only place the plant can come from.
      SELECT * FROM zknit_roll_qc
        WHERE arbpl = @ls_key-arbpl
          AND mrno  = @ls_key-mrno
        ORDER BY aedat DESCENDING, aezet DESCENDING
        INTO TABLE @lt_rows
        UP TO 1 ROWS.
      IF lt_rows IS NOT INITIAL.
        ls_row = lt_rows[ 1 ].
        ls_key-werks = ls_row-werks.
      ENDIF.
    ENDIF.

    IF ls_row IS NOT INITIAL.
      lt_rows = VALUE #( ( ls_row ) ).
      lt_out = rows_to_rolls( lt_rows ).
      es_roll = lt_out[ 1 ].
      es_roll-exists = abap_true.
      " The print log is the better source for the order when the row was
      " written before a print run was found.
      IF es_roll-aufnr IS INITIAL AND lt_print IS NOT INITIAL.
        es_roll-aufnr = lt_print[ 1 ]-aufnr.
      ENDIF.
      IF es_roll-print_date IS INITIAL AND lt_print IS NOT INITIAL.
        es_roll-print_date = lt_print[ 1 ]-pdate.
      ENDIF.
      RETURN.
    ENDIF.

    " 3. A roll nobody has scanned yet. Plant and order from the print
    "    run, or - as ZPACK01 does when the run is missing - from the
    "    single open order of the work centre.
    es_roll-arbpl = ls_key-arbpl.
    es_roll-mrno  = ls_key-mrno.
    es_roll-zmrno = ls_key-zmrno.
    es_roll-werks = ls_key-werks.

    IF lt_print IS NOT INITIAL.
      es_roll-aufnr      = lt_print[ 1 ]-aufnr.
      es_roll-print_date = lt_print[ 1 ]-pdate.
    ELSE.
      SELECT aufnr, dwerk FROM zsolopenord
        WHERE arbpl = @ls_key-arbpl
        INTO TABLE @DATA(lt_open).
      IF ls_key-werks IS NOT INITIAL.
        DELETE lt_open WHERE dwerk <> ls_key-werks.
      ENDIF.
      IF lines( lt_open ) = 1.
        es_roll-aufnr = lt_open[ 1 ]-aufnr.
        IF es_roll-werks IS INITIAL.
          es_roll-werks = lt_open[ 1 ]-dwerk.
        ENDIF.
      ELSEIF lines( lt_open ) > 1.
        ev_error = |Machine { ls_key-arbpl } has more than one open order and no print record for roll { ls_key-mrno ALPHA = OUT } - print the label from ZSBAR first|.
        RETURN.
      ENDIF.
    ENDIF.

    IF es_roll-werks IS INITIAL.
      " Last resort: the work centre itself names its plant.
      SELECT SINGLE werks FROM crhd
        WHERE objty = 'A' AND arbpl = @ls_key-arbpl
        INTO @es_roll-werks.
      IF sy-subrc <> 0.
        ev_error = |{ ls_key-arbpl } is not a known knitting machine|.
        RETURN.
      ENDIF.
    ENDIF.

    IF es_roll-aufnr IS NOT INITIAL.
      SELECT SINGLE matnr FROM afpo
        WHERE aufnr = @es_roll-aufnr
        INTO @es_roll-matnr.
      IF es_roll-matnr IS NOT INITIAL.
        SELECT SINGLE maktx FROM makt
          WHERE matnr = @es_roll-matnr AND spras = @sy-langu
          INTO @es_roll-maktx.
      ENDIF.
    ENDIF.

    " Packed already? Then the roll went straight to packing without QC.
    SELECT boxno, grade, pdate, netwt FROM zpp_pack
      WHERE zmrno  = @ls_key-zmrno
        AND werks  = @es_roll-werks
        AND delind = @space
      ORDER BY pdate DESCENDING, time DESCENDING
      INTO TABLE @DATA(lt_pack)
      UP TO 1 ROWS.
    IF lt_pack IS NOT INITIAL.
      es_roll-pack_boxno = lt_pack[ 1 ]-boxno.
      es_roll-pack_grade = lt_pack[ 1 ]-grade.
      es_roll-pack_date  = lt_pack[ 1 ]-pdate.
      es_roll-pack_netwt = lt_pack[ 1 ]-netwt.
    ENDIF.

  ENDMETHOD.


  METHOD read_row.
    CLEAR rs_row.
    SELECT SINGLE * FROM zknit_roll_qc
      WHERE werks = @is_key-werks
        AND arbpl = @is_key-arbpl
        AND mrno  = @is_key-mrno
      INTO @rs_row.
  ENDMETHOD.


  METHOD stamp_change.
    IF cs_row-erdat IS INITIAL.
      cs_row-ernam = iv_user.
      cs_row-erdat = sy-datum.
      cs_row-erzet = sy-uzeit.
    ENDIF.
    cs_row-aenam = iv_user.
    cs_row-aedat = sy-datum.
    cs_row-aezet = sy-uzeit.
  ENDMETHOD.


  METHOD days_since.
    IF iv_date IS INITIAL.
      rv_days = 0.
    ELSE.
      rv_days = sy-datum - iv_date.
    ENDIF.
  ENDMETHOD.


  METHOD record_physical_qc.

    DATA: ls_row  TYPE zknit_roll_qc,
          ls_roll TYPE ty_roll.

    CLEAR: es_roll, ev_error.

    IF iv_grade IS INITIAL.
      ev_error = 'Choose a grade'.
      RETURN.
    ENDIF.
    SELECT SINGLE gcode FROM zpp_grade
      WHERE auart = @gc_auart_knt AND gcode = @iv_grade
      INTO @DATA(lv_gcode).
    IF sy-subrc <> 0.
      ev_error = |Grade { iv_grade } is not a knitting grade|.
      RETURN.
    ENDIF.

    " Order and material are resolved the same way the screen saw them.
    resolve_roll( EXPORTING iv_scan = is_key-zmrno iv_werks = is_key-werks
                  IMPORTING es_roll = ls_roll ev_error = ev_error ).
    IF ev_error IS NOT INITIAL.
      RETURN.
    ENDIF.

    ls_row = read_row( VALUE #( werks = ls_roll-werks arbpl = ls_roll-arbpl mrno = ls_roll-mrno ) ).

    IF ls_row IS INITIAL.
      ls_row-werks = ls_roll-werks.
      ls_row-arbpl = ls_roll-arbpl.
      ls_row-mrno  = ls_roll-mrno.
      ls_row-zmrno = ls_roll-zmrno.
    ENDIF.
    IF ls_row-aufnr IS INITIAL.
      ls_row-aufnr = ls_roll-aufnr.
    ENDIF.
    IF ls_row-matnr IS INITIAL.
      ls_row-matnr = ls_roll-matnr.
    ENDIF.
    IF ls_row-print_date IS INITIAL.
      ls_row-print_date = ls_roll-print_date.
    ENDIF.

    ls_row-pqc_date    = sy-datum.
    ls_row-pqc_time    = sy-uzeit.
    ls_row-pqc_user    = iv_user.
    ls_row-pqc_grade   = iv_grade.
    ls_row-pqc_defects = iv_defects.
    ls_row-pqc_remark  = iv_remark.

    " The dyeing-QC tick. Set: the hold starts now unless the sample is
    " already further along. Cleared: only a sample that has not reached
    " the lab can be called back.
    IF iv_dye_sample = abap_true.
      IF ls_row-dqc_status = gc_dqc_none.
        ls_row-dqc_status    = gc_dqc_sent.
        ls_row-dqc_sent_date = sy-datum.
        ls_row-dqc_sent_time = sy-uzeit.
        ls_row-dqc_sent_user = iv_user.
      ENDIF.
    ELSEIF ls_row-dqc_status = gc_dqc_sent.
      CLEAR: ls_row-dqc_status, ls_row-dqc_sent_date, ls_row-dqc_sent_time, ls_row-dqc_sent_user.
    ENDIF.

    stamp_change( EXPORTING iv_user = iv_user CHANGING cs_row = ls_row ).

    MODIFY zknit_roll_qc FROM @ls_row.
    IF sy-subrc <> 0.
      ev_error = |Roll { ls_row-zmrno } could not be saved|.
      RETURN.
    ENDIF.

    resolve_roll( EXPORTING iv_scan = ls_row-zmrno iv_werks = ls_row-werks
                  IMPORTING es_roll = es_roll ev_error = ev_error ).

  ENDMETHOD.


  METHOD record_dye_received.

    DATA: ls_row  TYPE zknit_roll_qc,
          ls_roll TYPE ty_roll.

    CLEAR: es_roll, ev_error.

    resolve_roll( EXPORTING iv_scan = is_key-zmrno iv_werks = is_key-werks
                  IMPORTING es_roll = ls_roll ev_error = ev_error ).
    IF ev_error IS NOT INITIAL.
      RETURN.
    ENDIF.

    ls_row = read_row( VALUE #( werks = ls_roll-werks arbpl = ls_roll-arbpl mrno = ls_roll-mrno ) ).
    IF ls_row IS INITIAL.
      " The lab has the sample, so the roll exists - record it, marked as
      " never having been through Physical QC (no grade).
      ls_row-werks      = ls_roll-werks.
      ls_row-arbpl      = ls_roll-arbpl.
      ls_row-mrno       = ls_roll-mrno.
      ls_row-zmrno      = ls_roll-zmrno.
      ls_row-aufnr      = ls_roll-aufnr.
      ls_row-matnr      = ls_roll-matnr.
      ls_row-print_date = ls_roll-print_date.
    ENDIF.

    CASE ls_row-dqc_status.
      WHEN gc_dqc_cleared OR gc_dqc_failed.
        ev_error = |Roll { ls_row-zmrno } already has a dyeing result ({ ls_row-dqc_status }) from { ls_row-dqc_res_date DATE = USER }|.
        RETURN.
      WHEN gc_dqc_received.
        ev_error = |Roll { ls_row-zmrno } was already received on { ls_row-dqc_recv_date DATE = USER }|.
        RETURN.
    ENDCASE.

    IF ls_row-dqc_sent_date IS INITIAL.
      ls_row-dqc_sent_date = sy-datum.
      ls_row-dqc_sent_time = sy-uzeit.
      ls_row-dqc_sent_user = iv_user.
    ENDIF.
    ls_row-dqc_status    = gc_dqc_received.
    ls_row-dqc_recv_date = sy-datum.
    ls_row-dqc_recv_time = sy-uzeit.
    ls_row-dqc_recv_user = iv_user.

    stamp_change( EXPORTING iv_user = iv_user CHANGING cs_row = ls_row ).

    MODIFY zknit_roll_qc FROM @ls_row.
    IF sy-subrc <> 0.
      ev_error = |Roll { ls_row-zmrno } could not be saved|.
      RETURN.
    ENDIF.

    resolve_roll( EXPORTING iv_scan = ls_row-zmrno iv_werks = ls_row-werks
                  IMPORTING es_roll = es_roll ev_error = ev_error ).

  ENDMETHOD.


  METHOD record_dye_result.

    DATA: ls_row  TYPE zknit_roll_qc,
          ls_roll TYPE ty_roll.

    CLEAR: es_roll, ev_error.

    IF iv_result <> gc_dqc_cleared AND iv_result <> gc_dqc_failed.
      ev_error = 'Result must be Cleared or Failed'.
      RETURN.
    ENDIF.

    resolve_roll( EXPORTING iv_scan = is_key-zmrno iv_werks = is_key-werks
                  IMPORTING es_roll = ls_roll ev_error = ev_error ).
    IF ev_error IS NOT INITIAL.
      RETURN.
    ENDIF.

    ls_row = read_row( VALUE #( werks = ls_roll-werks arbpl = ls_roll-arbpl mrno = ls_roll-mrno ) ).
    IF ls_row IS INITIAL.
      ev_error = |Roll { ls_roll-zmrno } has no QC record - it was never sent to Dyeing QC|.
      RETURN.
    ENDIF.
    IF ls_row-dqc_status = gc_dqc_none.
      ev_error = |Roll { ls_row-zmrno } was not sent to Dyeing QC|.
      RETURN.
    ENDIF.

    " A result may be corrected (C -> F or F -> C) - it is the same lab
    " overriding itself, and the remark says why. The previous verdict is
    " kept in the remark so it is not silently lost.
    IF ls_row-dqc_status = gc_dqc_cleared OR ls_row-dqc_status = gc_dqc_failed.
      IF ls_row-dqc_status = iv_result.
        ev_error = |Roll { ls_row-zmrno } already has this result from { ls_row-dqc_res_date DATE = USER }|.
        RETURN.
      ENDIF.
      ls_row-dqc_remark = |Was { ls_row-dqc_status } on { ls_row-dqc_res_date DATE = USER }. { iv_remark }|.
    ELSE.
      ls_row-dqc_remark = iv_remark.
    ENDIF.

    IF ls_row-dqc_recv_date IS INITIAL.
      ls_row-dqc_recv_date = sy-datum.
      ls_row-dqc_recv_time = sy-uzeit.
      ls_row-dqc_recv_user = iv_user.
    ENDIF.
    ls_row-dqc_status   = iv_result.
    ls_row-dqc_res_date = sy-datum.
    ls_row-dqc_res_time = sy-uzeit.
    ls_row-dqc_res_user = iv_user.

    stamp_change( EXPORTING iv_user = iv_user CHANGING cs_row = ls_row ).

    MODIFY zknit_roll_qc FROM @ls_row.
    IF sy-subrc <> 0.
      ev_error = |Roll { ls_row-zmrno } could not be saved|.
      RETURN.
    ENDIF.

    resolve_roll( EXPORTING iv_scan = ls_row-zmrno iv_werks = ls_row-werks
                  IMPORTING es_roll = es_roll ev_error = ev_error ).

  ENDMETHOD.


  METHOD check_pack.

    DATA: ls_key TYPE ty_key,
          ls_row TYPE zknit_roll_qc,
          lv_err TYPE string.

    CLEAR: ev_block, ev_message, ev_dqc_status, ev_pqc_grade.

    parse_mrno( EXPORTING iv_scan = iv_zmrno iv_werks = iv_werks
                IMPORTING es_key = ls_key ev_error = lv_err ).
    IF lv_err IS NOT INITIAL.
      " Not a roll label at all - nothing to hold. ZPACK01's own checks
      " decide what to do with the value.
      RETURN.
    ENDIF.

    ls_row = read_row( ls_key ).

    IF ls_row IS INITIAL.
      " Advisory only: the roll never went through Physical QC. Made a
      " hard stop by changing the two lines in VALIDATE_MRNO, once every
      " roll is being scanned on the floor.
      ev_message = |Roll { ls_key-zmrno } has no Physical QC record|.
      RETURN.
    ENDIF.

    ev_dqc_status = ls_row-dqc_status.
    ev_pqc_grade  = ls_row-pqc_grade.

    CASE ls_row-dqc_status.
      WHEN gc_dqc_sent OR gc_dqc_received.
        ev_block   = abap_true.
        ev_message = |Roll { ls_key-zmrno } is under Dyeing QC since { ls_row-dqc_sent_date DATE = USER }| &&
                     | ({ days_since( ls_row-dqc_sent_date ) } days) - do not pack until the lab clears it|.
      WHEN gc_dqc_failed.
        " Blocked only when 1ST quality is actually chosen; with no grade
        " yet (the MR-number field is validated before the grade is typed)
        " the message is advisory and ZPACK01 defaults the grade down.
        IF iv_grade = gc_grade_first.
          ev_block   = abap_true.
          ev_message = |Roll { ls_key-zmrno } FAILED Dyeing QC on { ls_row-dqc_res_date DATE = USER }| &&
                       | - it cannot be packed as 1ST quality; choose a lower grade| &&
                       COND #( WHEN ls_row-dqc_remark IS NOT INITIAL THEN | ({ ls_row-dqc_remark })| ELSE || ).
        ELSE.
          ev_message = |Roll { ls_key-zmrno } failed Dyeing QC on { ls_row-dqc_res_date DATE = USER } - not 1ST quality| &&
                       COND #( WHEN ls_row-dqc_remark IS NOT INITIAL THEN | ({ ls_row-dqc_remark })| ELSE || ).
        ENDIF.
      WHEN OTHERS.
        IF ls_row-pqc_grade = 'R'.
          ev_block   = abap_true.
          ev_message = |Roll { ls_key-zmrno } was REJECTED at Physical QC on { ls_row-pqc_date DATE = USER }| &&
                       COND #( WHEN ls_row-pqc_remark IS NOT INITIAL THEN | ({ ls_row-pqc_remark })| ELSE || ).
        ENDIF.
    ENDCASE.

  ENDMETHOD.


  METHOD rows_to_rolls.

    DATA: lt_grade TYPE tt_grade.

    FIELD-SYMBOLS <ls_row> TYPE zknit_roll_qc.

    IF it_rows IS INITIAL.
      RETURN.
    ENDIF.

    lt_grade = get_grades( ).

    LOOP AT it_rows ASSIGNING <ls_row>.
      APPEND INITIAL LINE TO rt_rolls ASSIGNING FIELD-SYMBOL(<ls_out>).
      <ls_out>-werks         = <ls_row>-werks.
      <ls_out>-arbpl         = <ls_row>-arbpl.
      <ls_out>-mrno          = <ls_row>-mrno.
      <ls_out>-zmrno         = <ls_row>-zmrno.
      <ls_out>-aufnr         = <ls_row>-aufnr.
      <ls_out>-matnr         = <ls_row>-matnr.
      <ls_out>-print_date    = <ls_row>-print_date.
      <ls_out>-pqc_date      = <ls_row>-pqc_date.
      <ls_out>-pqc_time      = <ls_row>-pqc_time.
      <ls_out>-pqc_user      = <ls_row>-pqc_user.
      <ls_out>-pqc_grade     = <ls_row>-pqc_grade.
      <ls_out>-pqc_defects   = <ls_row>-pqc_defects.
      <ls_out>-pqc_remark    = <ls_row>-pqc_remark.
      <ls_out>-dqc_status    = <ls_row>-dqc_status.
      <ls_out>-dqc_sent_date = <ls_row>-dqc_sent_date.
      <ls_out>-dqc_recv_date = <ls_row>-dqc_recv_date.
      <ls_out>-dqc_res_date  = <ls_row>-dqc_res_date.
      <ls_out>-dqc_res_user  = <ls_row>-dqc_res_user.
      <ls_out>-dqc_remark    = <ls_row>-dqc_remark.
      <ls_out>-exists        = abap_true.
      IF <ls_row>-dqc_status = gc_dqc_sent OR <ls_row>-dqc_status = gc_dqc_received.
        <ls_out>-days_pending = days_since( <ls_row>-dqc_sent_date ).
        <ls_out>-hold         = abap_true.
      ELSEIF <ls_row>-dqc_status = gc_dqc_failed.
        <ls_out>-hold         = abap_true.
      ENDIF.
      READ TABLE lt_grade INTO DATA(ls_grade) WITH KEY gcode = <ls_row>-pqc_grade.
      IF sy-subrc = 0.
        <ls_out>-pqc_grade_txt = ls_grade-gdesc.
      ENDIF.
    ENDLOOP.

    " Material texts and packing state in two reads for the whole list.
    SELECT matnr, maktx FROM makt
      FOR ALL ENTRIES IN @rt_rolls
      WHERE matnr = @rt_rolls-matnr AND spras = @sy-langu
      INTO TABLE @DATA(lt_makt).
    SORT lt_makt BY matnr.

    SELECT zmrno, werks, boxno, grade, pdate, netwt FROM zpp_pack
      FOR ALL ENTRIES IN @rt_rolls
      WHERE zmrno  = @rt_rolls-zmrno
        AND werks  = @rt_rolls-werks
        AND delind = @space
      INTO TABLE @DATA(lt_pack).
    SORT lt_pack BY werks zmrno pdate DESCENDING.

    LOOP AT rt_rolls ASSIGNING <ls_out>.
      READ TABLE lt_makt INTO DATA(ls_makt) WITH KEY matnr = <ls_out>-matnr BINARY SEARCH.
      IF sy-subrc = 0.
        <ls_out>-maktx = ls_makt-maktx.
      ENDIF.
      READ TABLE lt_pack INTO DATA(ls_pack) WITH KEY werks = <ls_out>-werks zmrno = <ls_out>-zmrno BINARY SEARCH.
      IF sy-subrc = 0.
        <ls_out>-pack_boxno = ls_pack-boxno.
        <ls_out>-pack_grade = ls_pack-grade.
        <ls_out>-pack_date  = ls_pack-pdate.
        <ls_out>-pack_netwt = ls_pack-netwt.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.


  METHOD get_hold_list.
    SELECT * FROM zknit_roll_qc
      WHERE werks IN @it_werks
        AND dqc_status IN ( @gc_dqc_sent, @gc_dqc_received, @gc_dqc_failed )
      ORDER BY dqc_status, dqc_sent_date, arbpl, mrno
      INTO TABLE @DATA(lt_rows).
    rt_rolls = rows_to_rolls( lt_rows ).
  ENDMETHOD.


  METHOD get_pending_dye.
    SELECT * FROM zknit_roll_qc
      WHERE werks IN @it_werks
        AND dqc_status IN ( @gc_dqc_sent, @gc_dqc_received )
      ORDER BY dqc_sent_date, dqc_sent_time, arbpl, mrno
      INTO TABLE @DATA(lt_rows).
    rt_rolls = rows_to_rolls( lt_rows ).
  ENDMETHOD.


  METHOD get_production.
    DATA: lr_aufnr TYPE RANGE OF aufnr,
          lr_arbpl TYPE RANGE OF arbpl.
    IF iv_aufnr IS NOT INITIAL.
      lr_aufnr = VALUE #( ( sign = 'I' option = 'EQ' low = iv_aufnr ) ).
    ENDIF.
    IF iv_arbpl IS NOT INITIAL.
      lr_arbpl = VALUE #( ( sign = 'I' option = 'EQ' low = iv_arbpl ) ).
    ENDIF.
    SELECT * FROM zknit_roll_qc
      WHERE werks IN @it_werks
        AND pqc_date BETWEEN @iv_date_from AND @iv_date_to
        AND aufnr IN @lr_aufnr
        AND arbpl IN @lr_arbpl
      ORDER BY pqc_date DESCENDING, pqc_time DESCENDING, arbpl, mrno
      INTO TABLE @DATA(lt_rows)
      UP TO 2000 ROWS.
    rt_rolls = rows_to_rolls( lt_rows ).
  ENDMETHOD.


  METHOD get_defect_codes.
    " Plant rows and the blank-plant rows together; a plant row hides a
    " blank-plant row with the same code.
    SELECT werks, dcode, descr, sortno, inactive FROM zknit_qc_defect
      WHERE ( werks = @iv_werks OR werks = @space )
        AND inactive = @space
      ORDER BY sortno, dcode, werks DESCENDING
      INTO TABLE @DATA(lt_all).
    LOOP AT lt_all INTO DATA(ls_d).
      READ TABLE rt_defects TRANSPORTING NO FIELDS WITH KEY dcode = ls_d-dcode.
      IF sy-subrc <> 0.
        APPEND CORRESPONDING #( ls_d ) TO rt_defects.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.


  METHOD get_grades.
    SELECT gcode, gdesc FROM zpp_grade
      WHERE auart = @gc_auart_knt
      ORDER BY gcode
      INTO TABLE @rt_grades.
  ENDMETHOD.

ENDCLASS.
