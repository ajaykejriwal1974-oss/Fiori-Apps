CLASS zcl_zsol_obd_create DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

* ----------------------------------------------------------------------
* Creates the real Challan for one packing list: the SAP outbound
* delivery, with the packing list's cartons/pallets (existing handling
* units) packed onto it and goods issue posted - exactly what ZSDOBDN
* (report ZSD_OBD_AUTOMATION_NEW) does from the SAP GUI, made callable
* from the Scan Suite's OData service (ZCL_ZSOL_CHALLAN_PACK__DPC_EXT,
* Create Challan with App = 'D').
*
* WHAT IS TAKEN FROM ZSDOBDN, STEP FOR STEP (06.09.2026)
*
*   1. Order item VBAK/VBAP; the plant is the shipping point.
*   2. ZPP_PACK rows of the packing list (VBELN + POSNR + PKLST, not
*      deleted). Each carton's handling unit is its box number, ALPHA-
*      padded to EXIDV - the same derivation ZSDOBDN uses, and it must
*      exist in VEKP as a free HU: VPOBJ 12, status 0020 (stock at a
*      non-HU location), not inside a higher-level HU, one VEPO item.
*   3. The delivery quantity is the SUM of the HUs' VEPO quantities (not
*      ZPP_PACK-NETWT), unit KG, as ZSDOBDN posts it.
*   4. Multi-batch orders (ZVBAP_BATCH has rows for the item) get one
*      delivery per merge number, with LIPS-CHARG = the merge number;
*      everything else gets one delivery for the packing list.
*   5. Pre-checks before anything posts: packaging materials of pallets /
*      trolleys not locked in MARA and in stock at storage location PAST;
*      customer not credit-blocked (ZSOL_CREDIT_BLOCK).
*   6. VL01N by batch input, MODE 'N' (there is no screen here): create
*      with reference to the order item, actual GI date, quantity, pack
*      each carton's HU directly onto the delivery item, partners
*      unchanged, then Post Goods Issue - the same key sequence as the
*      report, verified against SAPMV50A 4001/1000/2000 and SAPLV51G 6000.
*      VL 311 in the message log carries the new delivery number.
*   7. Transporter code / truck number written to LIKP-ZZTRCODE /
*      ZZTRCKNO as the report does (direct UPDATE - these are customer
*      fields with no API).
*   8. 621 (goods issue of returnable packaging to the customer) through
*      BAPI_GOODSMVT_CREATE for pallet and trolley materials, header text
*      = the delivery. Failures are reported and written to ZSOL_621MSG,
*      as in the report; they do not undo the delivery.
*   9. ZSOL_CHALLAN_LOG rows through ZCL_ZSOL_CHALLAN_PACK=>PACK_BOXES
*      with the delivery number that was actually created - so the Scan
*      Suite's pending lists and the ZDLVCHALLAN app see the challan.
*
* SECURITY CONFIRMS BEFORE THE CHALLAN (07.09.2026)
*
*   ZSDOBDN's "boxes have been scanned by Security" test on
*   ZSOL_HUDISPATCH was left out on 05.09 because the app's order then
*   was Create Challan -> Security Loading. The process owner inverted it
*   on 07.09: Packing List -> Security Loading -> Create Challan. So the
*   test is back, for every plant, and stricter than the report's: with
*   IV_LOADED_ONLY (the default) only the cartons Security has confirmed
*   for THIS packing list go on the delivery, unconfirmed cartons are
*   reported with type 'W' and stay on the list for a later challan, and
*   a list with no confirmed carton posts nothing.
*
*   "Confirmed" is the rule of ZCL_ZSOL_CHALLAN_PACK__DPC_EXT (which is
*   what the two screens show), word for word: a ZSOL_HUDISPATCH row for
*   the box number, STATUS not 'E-', PCK_LST equal to the packing list,
*   ERDAT on or after ZPP_PACK-PLDATE. Change one, change both.
*
* WHAT IS DELIBERATELY NOT TAKEN
*
*   - GR slip number and incoterms: ZSDOBDN shows them on its ALV but
*     never posts them, so there is nothing to carry.
*   - MODIFY ZSOL_HUDISPATCH at the end: it re-saved rows it had read
*     unchanged.
*
* Everything is returned in RS_RESULT; nothing here raises. Per-box
* verdicts go in BOXES, one row per delivery attempt in DELIVERIES, and
* the complete message trail (batch-input messages, BAPI returns) in LOG
* so the operator can read why a run stopped.
* ----------------------------------------------------------------------

  PUBLIC SECTION.

    TYPES: BEGIN OF ty_box,
             boxno   TYPE zpp_pack-boxno,
             exidv   TYPE vekp-exidv,
             mergno  TYPE zpp_pack-mergno,
             ptype   TYPE zpp_pack-ptype,
             netwt   TYPE vepo-vemng,
             type    TYPE bapi_mtype,
             message TYPE string,
           END OF ty_box .
    TYPES tt_box TYPE STANDARD TABLE OF ty_box WITH EMPTY KEY .

    TYPES: BEGIN OF ty_delivery,
             mergno     TYPE zpp_pack-mergno,
             deliv_numb TYPE likp-vbeln,
             boxes      TYPE i,
             lfimg      TYPE vepo-vemng,
             type       TYPE bapi_mtype,
             message    TYPE string,
           END OF ty_delivery .
    TYPES tt_delivery TYPE STANDARD TABLE OF ty_delivery WITH EMPTY KEY .

    TYPES: BEGIN OF ty_result,
             type       TYPE bapi_mtype,
             message    TYPE string,
             deliveries TYPE tt_delivery,
             boxes      TYPE tt_box,
             log        TYPE string_table,
           END OF ty_result .

    METHODS create_for_packing_list
      IMPORTING
        !iv_vbeln        TYPE vbeln_va
        !iv_posnr        TYPE posnr_va
        !iv_pklst        TYPE zpp_pack-pklst
        !iv_wadat        TYPE likp-wadat_ist
        !iv_trcode       TYPE likp-zztrcode OPTIONAL
        !iv_trckno       TYPE likp-zztrckno OPTIONAL
        !iv_loaded_only  TYPE abap_bool DEFAULT abap_true
      RETURNING
        VALUE(rs_result) TYPE ty_result .

  PRIVATE SECTION.

    TYPES: BEGIN OF ty_so,
             vbeln  TYPE vbak-vbeln,
             kunnr  TYPE vbak-kunnr,
             kkber  TYPE vbak-kkber,
             posnr  TYPE vbap-posnr,
             matnr  TYPE vbap-matnr,
             werks  TYPE vbap-werks,
             lgort  TYPE vbap-lgort,
             kunwe  TYPE vbpa-kunnr,
           END OF ty_so .

    TYPES: BEGIN OF ty_pallet,
             mergno TYPE zpp_pack-mergno,
             matnr  TYPE zpp_pack-tpply,
             erfmg  TYPE zpp_pack-tpqty,
           END OF ty_pallet .
*   DEFAULT KEY on purpose: COLLECT sums ERFMG per MERGNO + MATNR.
    TYPES tt_pallet TYPE STANDARD TABLE OF ty_pallet WITH DEFAULT KEY .
    TYPES tt_pack   TYPE STANDARD TABLE OF zpp_pack WITH EMPTY KEY .

    TYPES: BEGIN OF ty_hu,
             venum  TYPE vekp-venum,
             exidv  TYPE vekp-exidv,
             vpobj  TYPE vekp-vpobj,
             uevel  TYPE vekp-uevel,
             status TYPE vekp-status,
             vemng  TYPE vepo-vemng,
             vepos  TYPE vepo-vepos,
           END OF ty_hu .

    DATA mt_bdc  TYPE STANDARD TABLE OF bdcdata WITH EMPTY KEY .
    DATA mt_msgs TYPE STANDARD TABLE OF bdcmsgcoll WITH EMPTY KEY .

    METHODS bdc_dynpro
      IMPORTING
        !iv_program TYPE clike
        !iv_dynpro  TYPE clike .
    METHODS bdc_field
      IMPORTING
        !iv_fnam TYPE clike
        !iv_fval TYPE clike .
    METHODS run_vl01n
      IMPORTING
        !is_so           TYPE ty_so
        !iv_wadat        TYPE likp-wadat_ist
        !it_boxes        TYPE tt_box
        !iv_qty          TYPE vepo-vemng
        !iv_charg        TYPE charg_d OPTIONAL
      EXPORTING
        !ev_deliv_numb   TYPE likp-vbeln
        !ev_message      TYPE string
      CHANGING
        !ct_log          TYPE string_table .
    METHODS post_621
      IMPORTING
        !is_so         TYPE ty_so
        !iv_wadat      TYPE likp-wadat_ist
        !iv_deliv_numb TYPE likp-vbeln
        !it_pallet     TYPE tt_pallet
      CHANGING
        !ct_log        TYPE string_table .
    METHODS collect_pallets
      IMPORTING
        !it_pack         TYPE tt_pack
      RETURNING
        VALUE(rt_pallet) TYPE tt_pallet .
    METHODS precheck
      IMPORTING
        !is_so           TYPE ty_so
        !it_pack         TYPE tt_pack
        !it_pallet       TYPE tt_pallet
      RETURNING
        VALUE(rv_error)  TYPE string .
    METHODS msg_text
      IMPORTING
        !is_msg        TYPE bdcmsgcoll
      RETURNING
        VALUE(rv_text) TYPE string .

ENDCLASS.



CLASS zcl_zsol_obd_create IMPLEMENTATION.


  METHOD create_for_packing_list.

    DATA: lt_pack    TYPE tt_pack,
          lt_hu      TYPE STANDARD TABLE OF ty_hu,
          lt_groups  TYPE STANDARD TABLE OF zpp_pack-mergno WITH DEFAULT KEY,
          lt_skipped TYPE tt_box,
          ls_so      TYPE ty_so,
          lv_errors  TYPE i,
          lv_mult    TYPE abap_bool,
          lv_wadat   TYPE likp-wadat_ist.

    rs_result-type = 'E'.

    lv_wadat = COND #( WHEN iv_wadat IS INITIAL THEN sy-datum ELSE iv_wadat ).
    IF lv_wadat > sy-datum.
      rs_result-message = 'Goods issue date is in the future'.
      RETURN.
    ENDIF.

*   1. The order item. The plant is the shipping point, as in ZSDOBDN.
    SELECT SINGLE a~vbeln, a~kunnr, a~kkber,
                  b~posnr, b~matnr, b~werks, b~lgort
      FROM vbak AS a
      INNER JOIN vbap AS b ON b~vbeln = a~vbeln
      WHERE a~vbeln = @iv_vbeln
        AND b~posnr = @iv_posnr
      INTO CORRESPONDING FIELDS OF @ls_so.
    IF sy-subrc <> 0.
      rs_result-message = |Sales order { iv_vbeln ALPHA = OUT } item { iv_posnr ALPHA = OUT } does not exist|.
      RETURN.
    ENDIF.

*   Ship-to party for the 621 posting.
    SELECT SINGLE kunnr FROM vbpa
      WHERE vbeln = @iv_vbeln
        AND posnr = '000000'
        AND parvw = 'WE'
      INTO @ls_so-kunwe.
    IF ls_so-kunwe IS INITIAL.
      ls_so-kunwe = ls_so-kunnr.
    ENDIF.

*   2. The packing list's cartons. One row per box - a box number that
*      exists in two fiscal years takes the newer row, as PACK_BOXES does.
    SELECT * FROM zpp_pack
      WHERE vbeln = @iv_vbeln
        AND posnr = @iv_posnr
        AND pklst = @iv_pklst
        AND pldel = @space
      ORDER BY boxno ASCENDING, gjahr DESCENDING
      INTO TABLE @lt_pack.
    IF sy-subrc <> 0.
      rs_result-message = |Packing list { iv_pklst ALPHA = OUT } has no cartons for order { iv_vbeln ALPHA = OUT } item { iv_posnr ALPHA = OUT }|.
      RETURN.
    ENDIF.
    DELETE ADJACENT DUPLICATES FROM lt_pack COMPARING boxno.

*   2a. Security's confirmation (07.09.2026). Only cartons Security has
*       scanned onto the vehicle for THIS packing list go on the delivery
*       - the rule of ZCL_ZSOL_CHALLAN_PACK__DPC_EXT, word for word (see
*       the class comment). The rest are reported 'W' and stay on the
*       packing list; a list with no confirmed carton posts nothing.
    IF iv_loaded_only = abap_true.
      SELECT boxno, pck_lst, erdat, status
        FROM zsol_hudispatch
        FOR ALL ENTRIES IN @lt_pack
        WHERE boxno = @lt_pack-boxno
        INTO TABLE @DATA(lt_disp).
      SORT lt_disp BY boxno.

      LOOP AT lt_pack INTO DATA(ls_chk).
        READ TABLE lt_disp INTO DATA(ls_disp) WITH KEY boxno = ls_chk-boxno BINARY SEARCH.
        IF sy-subrc = 0
           AND ls_disp-status  <> 'E-'
           AND ls_disp-pck_lst  = ls_chk-pklst
           AND ls_disp-erdat   >= ls_chk-pldate.
          CONTINUE.
        ENDIF.
        APPEND VALUE ty_box( boxno   = ls_chk-boxno
                             mergno  = ls_chk-mergno
                             ptype   = ls_chk-ptype
                             type    = 'W'
                             message = 'Not confirmed by Security Loading - left on the packing list' ) TO lt_skipped.
        DELETE lt_pack.
      ENDLOOP.

      IF lt_pack IS INITIAL.
        rs_result-boxes   = lt_skipped.
        rs_result-message = |None of the { lines( lt_skipped ) } carton(s) on packing list { iv_pklst ALPHA = OUT } is confirmed by Security Loading - nothing was posted. Scan them in Security Loading first.|.
        RETURN.
      ENDIF.
    ENDIF.

*   The handling unit of a carton is its box number, ALPHA-padded to the
*   20-character EXIDV. That is how ZSDOBDN finds it in VEKP; ZPP_PACK's
*   own EXIDV column is not trusted for this.
    LOOP AT lt_pack ASSIGNING FIELD-SYMBOL(<ls_p>).
      CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
        EXPORTING
          input  = <ls_p>-boxno
        IMPORTING
          output = <ls_p>-exidv.
    ENDLOOP.

*   3. The handling units, with their single VEPO item (quantity).
    SELECT a~venum, a~exidv, a~vpobj, a~uevel, a~status, b~vemng, b~vepos
      FROM vekp AS a
      INNER JOIN vepo AS b ON b~venum = a~venum
      FOR ALL ENTRIES IN @lt_pack
      WHERE a~exidv = @lt_pack-exidv
      INTO TABLE @lt_hu.
    SORT lt_hu BY exidv vepos.

    LOOP AT lt_pack INTO DATA(ls_pack).
      DATA(ls_box) = VALUE ty_box( boxno  = ls_pack-boxno
                                   exidv  = ls_pack-exidv
                                   mergno = ls_pack-mergno
                                   ptype  = ls_pack-ptype
                                   type   = 'S' ).

      READ TABLE lt_hu INTO DATA(ls_hu) WITH KEY exidv = ls_pack-exidv BINARY SEARCH.
      IF sy-subrc <> 0.
        ls_box-type    = 'E'.
        ls_box-message = 'No handling unit in VEKP for this carton - pack it first'.
      ELSEIF ls_hu-vpobj <> '12'.
        ls_box-type    = 'E'.
        ls_box-message = COND #( WHEN ls_hu-vpobj = '01'
                                 THEN 'Already packed onto a delivery'
                                 ELSE |Handling unit is assigned to object type { ls_hu-vpobj } - not a free HU| ).
      ELSEIF ls_hu-status <> '0020'.
        ls_box-type    = 'E'.
        ls_box-message = |Handling unit status { ls_hu-status } - must be 0020 (stock at non-HU location)|.
      ELSEIF ls_hu-uevel IS NOT INITIAL.
        ls_box-type    = 'E'.
        ls_box-message = |Carton is inside higher-level HU { ls_hu-uevel ALPHA = OUT } - unpack it first|.
      ELSE.
*       More than one VEPO item under one EXIDV is the "box split" ZSDOBDN
*       refuses: the delivery quantity would be wrong.
        DATA(lv_items) = REDUCE i( INIT n = 0 FOR h IN lt_hu WHERE ( exidv = ls_pack-exidv ) NEXT n = n + 1 ).
        IF lv_items > 1.
          ls_box-type    = 'E'.
          ls_box-message = |Box split: { lv_items } items in handling unit - cannot proceed|.
        ELSE.
          ls_box-netwt = ls_hu-vemng.
        ENDIF.
      ENDIF.

      IF ls_box-type = 'E'.
        lv_errors = lv_errors + 1.
      ENDIF.
      APPEND ls_box TO rs_result-boxes.
    ENDLOOP.

    IF lv_errors > 0.
      rs_result-message = |{ lv_errors } of { lines( rs_result-boxes ) } confirmed carton(s) cannot go on a challan - nothing was posted. See the carton list.|.
      APPEND LINES OF lt_skipped TO rs_result-boxes.
      RETURN.
    ENDIF.

*   4. Returnable packaging of pallets and trolleys (621 after the GI).
    DATA(lt_pallet) = collect_pallets( lt_pack ).

*   5. Pre-checks, all before the first posting.
    DATA(lv_pre) = precheck( is_so = ls_so it_pack = lt_pack it_pallet = lt_pallet ).
    IF lv_pre IS NOT INITIAL.
      rs_result-message = lv_pre.
      APPEND LINES OF lt_skipped TO rs_result-boxes.
      RETURN.
    ENDIF.

*   6. One delivery per merge number when the item is batch-split
*      (ZVBAP_BATCH), otherwise one delivery for the whole list.
    SELECT COUNT( * ) FROM zvbap_batch
      WHERE vbeln = @iv_vbeln
        AND posnr = @iv_posnr
      INTO @DATA(lv_batches).
    lv_mult = xsdbool( lv_batches > 0 ).

    IF lv_mult = abap_true.
      lt_groups = VALUE #( FOR b IN rs_result-boxes ( b-mergno ) ).
      SORT lt_groups.
      DELETE ADJACENT DUPLICATES FROM lt_groups.
    ELSE.
      APPEND space TO lt_groups.
    ENDIF.

    DATA(lo_log) = NEW zcl_zsol_challan_pack( ).
    DATA lv_ok TYPE i.

    LOOP AT lt_groups INTO DATA(lv_group).
      DATA(lt_grp_boxes) = COND tt_box( WHEN lv_mult = abap_true
                                        THEN VALUE #( FOR b IN rs_result-boxes WHERE ( mergno = lv_group ) ( b ) )
                                        ELSE rs_result-boxes ).
      DATA(lv_qty) = REDUCE vepo-vemng( INIT q TYPE vepo-vemng FOR b IN lt_grp_boxes NEXT q = q + b-netwt ).

      DATA(ls_deliv) = VALUE ty_delivery( mergno = lv_group
                                          boxes  = lines( lt_grp_boxes )
                                          lfimg  = lv_qty ).

      IF lv_qty <= 0.
        ls_deliv-type    = 'E'.
        ls_deliv-message = 'Handling units carry no quantity - delivery quantity would be zero'.
        APPEND ls_deliv TO rs_result-deliveries.
        CONTINUE.
      ENDIF.

      run_vl01n( EXPORTING is_so    = ls_so
                           iv_wadat = lv_wadat
                           it_boxes = lt_grp_boxes
                           iv_qty   = lv_qty
                           iv_charg = COND #( WHEN lv_mult = abap_true THEN lv_group ELSE space )
                 IMPORTING ev_deliv_numb = ls_deliv-deliv_numb
                           ev_message    = ls_deliv-message
                 CHANGING  ct_log        = rs_result-log ).

      IF ls_deliv-deliv_numb IS INITIAL.
        ls_deliv-type = 'E'.
        APPEND ls_deliv TO rs_result-deliveries.
        LOOP AT rs_result-boxes ASSIGNING FIELD-SYMBOL(<ls_b>).
          IF lv_mult = abap_true AND <ls_b>-mergno <> lv_group.
            CONTINUE.
          ENDIF.
          <ls_b>-type    = 'E'.
          <ls_b>-message = 'Delivery not created - ' && ls_deliv-message.
        ENDLOOP.
        CONTINUE.
      ENDIF.

      ls_deliv-type = 'S'.
      lv_ok = lv_ok + 1.

*     7. Transporter and truck, customer fields on LIKP (as ZSDOBDN).
      IF iv_trcode IS NOT INITIAL OR iv_trckno IS NOT INITIAL.
        UPDATE likp SET zztrcode = @iv_trcode,
                        zztrckno = @iv_trckno
                  WHERE vbeln = @ls_deliv-deliv_numb.
        IF sy-subrc = 0.
          COMMIT WORK AND WAIT.
          APPEND |Delivery { ls_deliv-deliv_numb ALPHA = OUT }: transporter { iv_trcode } / truck { iv_trckno } saved| TO rs_result-log.
        ELSE.
          APPEND |Delivery { ls_deliv-deliv_numb ALPHA = OUT }: transporter / truck could not be saved| TO rs_result-log.
        ENDIF.
      ENDIF.

*     8. 621 for pallets / trolleys of this group.
      DATA(lt_grp_pallet) = COND tt_pallet( WHEN lv_mult = abap_true
                                            THEN VALUE #( FOR p IN lt_pallet WHERE ( mergno = lv_group ) ( p ) )
                                            ELSE lt_pallet ).
      IF lt_grp_pallet IS NOT INITIAL.
        post_621( EXPORTING is_so         = ls_so
                            iv_wadat      = lv_wadat
                            iv_deliv_numb = ls_deliv-deliv_numb
                            it_pallet     = lt_grp_pallet
                  CHANGING  ct_log        = rs_result-log ).
      ENDIF.

*     9. The Scan Suite's own record of the challan, per carton, with the
*        delivery that was really created.
      lo_log->pack_boxes( EXPORTING it_boxes      = VALUE #( FOR b IN lt_grp_boxes
                                                             ( boxno = b-boxno vbeln = iv_vbeln posnr = iv_posnr ) )
                                    iv_deliv_numb = ls_deliv-deliv_numb
                          IMPORTING et_result     = DATA(lt_logged) ).

      LOOP AT rs_result-boxes ASSIGNING <ls_b>.
        IF lv_mult = abap_true AND <ls_b>-mergno <> lv_group.
          CONTINUE.
        ENDIF.
        <ls_b>-type    = 'S'.
        <ls_b>-message = |Delivery { ls_deliv-deliv_numb ALPHA = OUT } - goods issue posted|.
        READ TABLE lt_logged INTO DATA(ls_logged) WITH KEY boxno = |{ <ls_b>-boxno ALPHA = IN }|.
        IF sy-subrc = 0 AND ls_logged-type = 'E'.
          <ls_b>-message = <ls_b>-message && | (log: { ls_logged-message })|.
        ENDIF.
      ENDLOOP.

      ls_deliv-message = |Challan { ls_deliv-deliv_numb ALPHA = OUT } created: { ls_deliv-boxes } carton(s), { lv_qty DECIMALS = 3 } KG, goods issue posted|.
      APPEND ls_deliv TO rs_result-deliveries.
    ENDLOOP.

    IF lv_ok = 0.
      rs_result-type    = 'E'.
      rs_result-message = COND #( WHEN lines( rs_result-deliveries ) = 1
                                  THEN rs_result-deliveries[ 1 ]-message
                                  ELSE 'No delivery could be created - see the log' ).
    ELSEIF lv_ok < lines( rs_result-deliveries ).
      rs_result-type    = 'W'.
      rs_result-message = |{ lv_ok } of { lines( rs_result-deliveries ) } deliveries created - see the log for the rest|.
    ELSE.
      rs_result-type    = 'S'.
      rs_result-message = COND #( WHEN lv_ok = 1
                                  THEN rs_result-deliveries[ 1 ]-message
                                  ELSE |{ lv_ok } deliveries created (one per batch)| ).
    ENDIF.

*   The cartons Security had not confirmed, after the ones that went. They
*   are still on the packing list for a later challan.
    IF lt_skipped IS NOT INITIAL.
      APPEND LINES OF lt_skipped TO rs_result-boxes.
      APPEND |{ lines( lt_skipped ) } carton(s) not confirmed by Security Loading - left on the packing list| TO rs_result-log.
      IF rs_result-type = 'S'.
        rs_result-message = rs_result-message && | - { lines( lt_skipped ) } unconfirmed carton(s) left on the list|.
      ENDIF.
    ENDIF.

  ENDMETHOD.


  METHOD collect_pallets.

*   Packaging materials that leave with the goods and are posted 621 to
*   the customer: pallet type 03 (tape, bottom, wood, plastic ply) and
*   trolley type 04 (the trolley itself, 1 each, plus its plies). Same
*   field set as ZSDOBDN's IT_PALLET, collected per merge number.
    DATA ls_pal TYPE ty_pallet.

    LOOP AT it_pack ASSIGNING FIELD-SYMBOL(<ls_p>).
      CLEAR ls_pal.
      ls_pal-mergno = <ls_p>-mergno.
      CASE <ls_p>-ptype.
        WHEN '03'.
          ls_pal-matnr = <ls_p>-tpply. ls_pal-erfmg = <ls_p>-tpqty. COLLECT ls_pal INTO rt_pallet.
          ls_pal-matnr = <ls_p>-btply. ls_pal-erfmg = <ls_p>-btqty. COLLECT ls_pal INTO rt_pallet.
          ls_pal-matnr = <ls_p>-wdply. ls_pal-erfmg = <ls_p>-wdqty. COLLECT ls_pal INTO rt_pallet.
          ls_pal-matnr = <ls_p>-plply. ls_pal-erfmg = <ls_p>-plqty. COLLECT ls_pal INTO rt_pallet.
        WHEN '04'.
          ls_pal-matnr = <ls_p>-troll. ls_pal-erfmg = 1.             COLLECT ls_pal INTO rt_pallet.
          ls_pal-matnr = <ls_p>-tpply. ls_pal-erfmg = <ls_p>-tpqty. COLLECT ls_pal INTO rt_pallet.
          ls_pal-matnr = <ls_p>-wdply. ls_pal-erfmg = <ls_p>-wdqty. COLLECT ls_pal INTO rt_pallet.
          ls_pal-matnr = <ls_p>-plply. ls_pal-erfmg = <ls_p>-plqty. COLLECT ls_pal INTO rt_pallet.
      ENDCASE.
    ENDLOOP.

    DELETE rt_pallet WHERE matnr IS INITIAL OR erfmg <= 0.

  ENDMETHOD.


  METHOD precheck.

    DATA: lt_enq   TYPE STANDARD TABLE OF seqg3,
          lv_garg  TYPE seqg3-garg,
          lv_bukrs TYPE t001k-bukrs,
          lv_block TYPE c LENGTH 1,
          lv_labst TYPE mard-labst,
          lv_short TYPE mard-labst.

*   Materials locked by another user (MARA enqueue) - ZSDOBDN's
*   MATERIAL_LOCK, without the popup.
    CALL FUNCTION 'ENQUE_READ'
      EXPORTING
        gclient = sy-mandt
        gname   = 'MARA'
        guname  = ''
      TABLES
        enq     = lt_enq
      EXCEPTIONS
        OTHERS  = 1.

    IF lt_enq IS NOT INITIAL.
      LOOP AT it_pallet INTO DATA(ls_pal).
        lv_garg = sy-mandt && ls_pal-matnr.
        READ TABLE lt_enq INTO DATA(ls_enq) WITH KEY garg = lv_garg.
        IF sy-subrc = 0.
          rv_error = |Material { ls_pal-matnr } is locked by user { ls_enq-guname } - try again later|.
          RETURN.
        ENDIF.
      ENDLOOP.
      LOOP AT it_pack ASSIGNING FIELD-SYMBOL(<ls_p>).
        lv_garg = sy-mandt && <ls_p>-matnr.
        READ TABLE lt_enq INTO ls_enq WITH KEY garg = lv_garg.
        IF sy-subrc = 0.
          rv_error = |Material { <ls_p>-matnr } is locked by user { ls_enq-guname } - try again later|.
          RETURN.
        ENDIF.
      ENDLOOP.
    ENDIF.

*   Returnable packaging must be in stock at PAST (CHECK_STOCK).
    LOOP AT it_pallet INTO ls_pal.
      CLEAR lv_labst.
      SELECT SINGLE labst FROM mard
        WHERE matnr = @ls_pal-matnr
          AND werks = @is_so-werks
          AND lgort = 'PAST'
        INTO @lv_labst.
      IF lv_labst < ls_pal-erfmg.
        lv_short = ls_pal-erfmg - lv_labst.
        rv_error = |Deficit of stock { lv_short DECIMALS = 3 } for packaging material { ls_pal-matnr } at { is_so-werks }/PAST|.
        RETURN.
      ENDIF.
    ENDLOOP.

*   Credit block (CREDIT_BLOCK).
    SELECT SINGLE bukrs FROM t001k WHERE bwkey = @is_so-werks INTO @lv_bukrs.

    CALL FUNCTION 'ZSOL_CREDIT_BLOCK'
      EXPORTING
        kunnr = is_so-kunnr
        kkber = is_so-kkber
        bukrs = lv_bukrs
      IMPORTING
        block = lv_block.
    IF lv_block = 'X'.
      rv_error = |Credit check failed for customer { is_so-kunnr ALPHA = OUT } - challan not created|.
      RETURN.
    ENDIF.

  ENDMETHOD.


  METHOD bdc_dynpro.
    APPEND VALUE #( program = iv_program dynpro = iv_dynpro dynbegin = 'X' ) TO mt_bdc.
  ENDMETHOD.


  METHOD bdc_field.
    APPEND VALUE #( fnam = iv_fnam fval = iv_fval ) TO mt_bdc.
  ENDMETHOD.


  METHOD msg_text.
    DATA lv_text TYPE string.
    MESSAGE ID is_msg-msgid TYPE 'S' NUMBER is_msg-msgnr
      WITH is_msg-msgv1 is_msg-msgv2 is_msg-msgv3 is_msg-msgv4
      INTO lv_text.
    rv_text = |{ is_msg-msgtyp } { is_msg-msgid } { is_msg-msgnr }: { lv_text }|.
  ENDMETHOD.


  METHOD run_vl01n.

*   The exact key sequence of ZSD_OBD_AUTOMATION_NEW -> POST_OBD_DOCUMENT,
*   both variants (with LIPS-CHARG for a batch-split item, without
*   otherwise). Field texts are built the way the report builds them -
*   date with WRITE TO and quantity with a P->C move - so they arrive in
*   the batch-input user's own formats, which is what the screens parse.
    DATA: lv_cdate TYPE c LENGTH 10,
          lv_qty   TYPE c LENGTH 15,
          lv_subrc TYPE sy-subrc.

    CLEAR: ev_deliv_numb, ev_message, mt_bdc, mt_msgs.

    WRITE iv_wadat TO lv_cdate.
    lv_qty = iv_qty.
    CONDENSE lv_qty.

    bdc_dynpro( iv_program = 'SAPMV50A' iv_dynpro = '4001' ).
    bdc_field( iv_fnam = 'BDC_CURSOR'  iv_fval = 'LV50C-ABPOS' ).
    bdc_field( iv_fnam = 'BDC_OKCODE'  iv_fval = '/00' ).
    bdc_field( iv_fnam = 'LIKP-VSTEL'  iv_fval = is_so-werks ).
    bdc_field( iv_fnam = 'LV50C-VBELN' iv_fval = is_so-vbeln ).
    bdc_field( iv_fnam = 'LV50C-ABPOS' iv_fval = is_so-posnr ).
    bdc_field( iv_fnam = 'LV50C-BIPOS' iv_fval = is_so-posnr ).
    bdc_field( iv_fnam = 'LIKP-LFART'  iv_fval = ' ' ).

    bdc_dynpro( iv_program = 'SAPMV50A' iv_dynpro = '1000' ).
    bdc_field( iv_fnam = 'BDC_OKCODE'  iv_fval = '=T\01' ).

    bdc_dynpro( iv_program = 'SAPMV50A' iv_dynpro = '1000' ).
    bdc_field( iv_fnam = 'BDC_OKCODE'     iv_fval = '=T\03' ).
    bdc_field( iv_fnam = 'BDC_CURSOR'     iv_fval = 'LIKP-WADAT_IST' ).
    bdc_field( iv_fnam = 'LIKP-WADAT_IST' iv_fval = lv_cdate ).
    bdc_field( iv_fnam = 'BDC_CURSOR'     iv_fval = 'LIPS-VRKME(01)' ).
    bdc_field( iv_fnam = 'LIPS-VRKME(01)' iv_fval = 'KG' ).

    bdc_dynpro( iv_program = 'SAPMV50A' iv_dynpro = '1000' ).
    bdc_field( iv_fnam = 'BDC_OKCODE'         iv_fval = '=VERP_T' ).
    bdc_field( iv_fnam = 'BDC_CURSOR'         iv_fval = 'LIPS-POSNR(01)' ).
    bdc_field( iv_fnam = 'LIPSD-G_LFIMG(01)'  iv_fval = lv_qty ).
    IF iv_charg IS NOT INITIAL.
      bdc_field( iv_fnam = 'LIPS-CHARG(01)'   iv_fval = iv_charg ).
    ENDIF.
    bdc_field( iv_fnam = 'RV50A-LIPS_SELKZ(01)' iv_fval = 'X' ).

    bdc_dynpro( iv_program = 'SAPLV51G' iv_dynpro = '6000' ).
    bdc_field( iv_fnam = 'BDC_OKCODE' iv_fval = '=UE6VDIR' ).
    bdc_field( iv_fnam = 'BDC_CURSOR' iv_fval = 'V51VE-VHILM(01)' ).

    LOOP AT it_boxes INTO DATA(ls_box).
      bdc_dynpro( iv_program = 'SAPLV51G' iv_dynpro = '6000' ).
      bdc_field( iv_fnam = 'BDC_OKCODE' iv_fval = '=ENTR' ).
      bdc_field( iv_fnam = 'BDC_CURSOR' iv_fval = 'VEKP-EXIDV' ).
      bdc_field( iv_fnam = 'VEKP-EXIDV' iv_fval = ls_box-boxno ).
    ENDLOOP.

    bdc_dynpro( iv_program = 'SAPLV51G' iv_dynpro = '6000' ).
    bdc_field( iv_fnam = 'BDC_OKCODE' iv_fval = '=UE6POS' ).
    bdc_field( iv_fnam = 'BDC_CURSOR' iv_fval = 'VEKP-EXIDV' ).

    bdc_dynpro( iv_program = 'SAPLV51G' iv_dynpro = '6000' ).
    bdc_field( iv_fnam = 'BDC_OKCODE' iv_fval = '=BACK' ).
    bdc_field( iv_fnam = 'BDC_CURSOR' iv_fval = 'V51VE-EXIDV(01)' ).

    bdc_dynpro( iv_program = 'SAPMV50A' iv_dynpro = '1000' ).
    bdc_field( iv_fnam = 'BDC_OKCODE' iv_fval = '=HPAR_T' ).
    bdc_field( iv_fnam = 'BDC_CURSOR' iv_fval = 'LIPS-MATNR(02)' ).

    bdc_dynpro( iv_program = 'SAPMV50A' iv_dynpro = '2000' ).
    bdc_field( iv_fnam = 'BDC_OKCODE' iv_fval = '/00' ).
    bdc_field( iv_fnam = 'BDC_CURSOR' iv_fval = 'GVS_TC_DATA-REC-PARTNER(05)' ).
    bdc_field( iv_fnam = 'GV_FILTER'  iv_fval = 'PARALL' ).

    bdc_dynpro( iv_program = 'SAPMV50A' iv_dynpro = '2000' ).
    bdc_field( iv_fnam = 'BDC_OKCODE' iv_fval = '=BACK_T' ).
    bdc_field( iv_fnam = 'BDC_CURSOR' iv_fval = 'GVS_TC_DATA-REC-PARTNER(05)' ).
    bdc_field( iv_fnam = 'GV_FILTER'  iv_fval = 'PARALL' ).

    bdc_dynpro( iv_program = 'SAPMV50A' iv_dynpro = '1000' ).
    bdc_field( iv_fnam = 'BDC_OKCODE' iv_fval = '=WABU_T' ).
    bdc_field( iv_fnam = 'BDC_CURSOR' iv_fval = 'LIPS-MATNR(02)' ).

    CALL TRANSACTION 'VL01N' WITH AUTHORITY-CHECK
      USING mt_bdc
      MODE 'N'
      UPDATE 'S'
      MESSAGES INTO mt_msgs.
    lv_subrc = sy-subrc.

    LOOP AT mt_msgs INTO DATA(ls_msg).
      APPEND msg_text( ls_msg ) TO ct_log.
    ENDLOOP.

*   VL 311: "Delivery & has been saved" - the number is in MSGV2.
    READ TABLE mt_msgs INTO ls_msg WITH KEY msgtyp = 'S' msgid = 'VL' msgnr = '311'.
    IF sy-subrc = 0.
      ev_deliv_numb = ls_msg-msgv2.
      COMMIT WORK AND WAIT.
      RETURN.
    ENDIF.

*   No delivery. The first error or abort message is the reason; a run
*   that ended on an unexpected screen leaves 00 344 (no batch input data
*   for screen) and is reported as such.
    LOOP AT mt_msgs INTO ls_msg WHERE msgtyp = 'E' OR msgtyp = 'A'.
      ev_message = msg_text( ls_msg ).
      EXIT.
    ENDLOOP.
    IF ev_message IS INITIAL.
      ev_message = COND #( WHEN mt_msgs IS INITIAL
                           THEN |VL01N returned { lv_subrc } without a message|
                           ELSE msg_text( mt_msgs[ lines( mt_msgs ) ] ) ).
    ENDIF.

  ENDMETHOD.


  METHOD post_621.

    DATA: ls_header  TYPE bapi2017_gm_head_01,
          ls_code    TYPE bapi2017_gm_code,
          lt_item    TYPE STANDARD TABLE OF bapi2017_gm_item_create,
          lt_return  TYPE STANDARD TABLE OF bapiret2,
          lv_mat_doc TYPE bapi2017_gm_head_ret-mat_doc,
          lv_year    TYPE bapi2017_gm_head_ret-doc_year,
          ls_log     TYPE zsol_621msg.

    ls_header-pstng_date = iv_wadat.
    ls_header-doc_date   = iv_wadat.
    ls_header-header_txt = iv_deliv_numb.
    ls_code-gm_code      = '06'.

    LOOP AT it_pallet INTO DATA(ls_pal).
      APPEND VALUE #( material_long = ls_pal-matnr
                      plant         = is_so-werks
                      stge_loc      = 'PAST'
                      move_type     = '621'
                      customer      = is_so-kunwe
                      entry_qnt     = ls_pal-erfmg
                      move_mat_long = ls_pal-matnr
                      move_plant    = is_so-werks ) TO lt_item.
    ENDLOOP.

    CALL FUNCTION 'BAPI_GOODSMVT_CREATE'
      EXPORTING
        goodsmvt_header  = ls_header
        goodsmvt_code    = ls_code
      IMPORTING
        materialdocument = lv_mat_doc
        matdocumentyear  = lv_year
      TABLES
        goodsmvt_item    = lt_item
        return           = lt_return.

    IF lv_mat_doc IS NOT INITIAL.
      CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
        EXPORTING
          wait = 'X'.
      APPEND |Delivery { iv_deliv_numb ALPHA = OUT }: 621 posted for { lines( lt_item ) } packaging material(s), document { lv_mat_doc }/{ lv_year }| TO ct_log.
    ELSE.
      CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.
      APPEND |Delivery { iv_deliv_numb ALPHA = OUT }: 621 for packaging NOT posted - post it in MB11 (see messages)| TO ct_log.
    ENDIF.

*   Every BAPI message, as ZSDOBDN records them in ZSOL_621MSG.
    LOOP AT lt_return INTO DATA(ls_ret).
      APPEND |621 { ls_ret-type } { ls_ret-id } { ls_ret-number }: { ls_ret-message }| TO ct_log.
      ls_log-mandt   = sy-mandt.
      ls_log-vbeln   = iv_deliv_numb.
      ls_log-msgid   = ls_ret-id.
      ls_log-msgnr   = ls_ret-number.
      ls_log-message = ls_ret-message.
      MODIFY zsol_621msg FROM ls_log.
    ENDLOOP.
    IF lt_return IS NOT INITIAL.
      COMMIT WORK.
    ENDIF.

  ENDMETHOD.

ENDCLASS.
