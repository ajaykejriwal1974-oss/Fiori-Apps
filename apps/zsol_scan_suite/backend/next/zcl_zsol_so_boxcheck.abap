CLASS zcl_zsol_so_boxcheck DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

* ----------------------------------------------------------------------
* Scan Suite - "why does this order show no boxes?" (06.09.2026)
*
* The Packing List asks ZRPT_SALES_SCAN (through ZSOL_PICK_DOWNLOAD_SRV)
* for the cartons an order may pick. That report finds a carton only when
* ALL of the following hold, and when any one fails the handheld just
* says "0 box(es) available to scan":
*
*   1. the handling unit holds the item's MATERIAL in the item's PLANT
*      and STORAGE LOCATION (VEPO vs VBAP-WERKS / VBAP-LGORT)
*   2. the handling unit's BATCH is one the order names - a ZVBAP_BATCH
*      row for the item, else VBAP-CHARG; an order that names no batch
*      only matches handling units with a blank batch
*   3. the handling unit is packed stock: VEKP status 0020/0030, object
*      01/12, and its ZPP_PACK row is posted (HUPOST or REPACK), not
*      deleted
*   4. the carton is free: ZPP_PACK-VBELN blank and the HU not already
*      on a delivery (VPOBJ 01)
*   5. the carton's SIZE and GRADE are among the ones the order's items
*      name (ZZSIZE/1/2, ZZGRADE/1/2 across the whole order); an order
*      that names none accepts any
*
* CHECK_ORDER applies the same rules to the packed stock of each item's
* material and reports, per item, how many handling units pass, and for
* the ones that do not, WHICH rule they fail and what value they carry -
* "12 HUs in DFGT (order says DFG1)", "8 HUs batch 0001234 (order names
* no batch)". Rule 2 is the usual culprit on the make-to-stock plants
* (2002 dyeing, 8001/8003 knitting), whose orders rarely carry a batch,
* so the batches that WOULD match are listed separately: assigning one
* to the item (ASSIGN_BATCH, the same ZVBAP_BATCH row the VA02 item
* screen writes) is what makes the boxes appear.
*
* Read-only except ASSIGN_BATCH / REMOVE_BATCH, which the data provider
* guards with the SOCHG screen grant. Both write a row to
* ZSOL_SOBATCH_LOG (who, when, which order/item/batch, added or removed)
* - ZVBAP_BATCH itself is key-only and keeps no history, and "who put this
* lot on that order" is the first question anyone asks.
* ----------------------------------------------------------------------

  PUBLIC SECTION.

    TYPES: BEGIN OF ty_item,
             vbeln       TYPE vbeln_va,
             posnr       TYPE posnr_va,
             matnr       TYPE matnr,
             arktx       TYPE arktx,
             werks       TYPE werks_d,
             lgort       TYPE lgort_d,
             charg       TYPE charg_d,
             kwmeng      TYPE kwmeng,
             vrkme       TYPE vrkme,
             dis_qty     TYPE kwmeng,
             open_qty    TYPE kwmeng,
             abgru       TYPE abgru_va,
             zzsize      TYPE c LENGTH 4,
             zzsiz1      TYPE c LENGTH 4,
             zzsiz2      TYPE c LENGTH 4,
             zzgrade     TYPE c LENGTH 1,
             zzgrad1     TYPE c LENGTH 1,
             zzgrad2     TYPE c LENGTH 1,
             so_batches  TYPE string,   " what the order names (ZVBAP_BATCH, else VBAP-CHARG)
             batch_src   TYPE c LENGTH 1, " A assigned (ZVBAP_BATCH), C item batch, blank none
             cand_cnt    TYPE i,        " packed, in-stock HUs of the material at the plant
             match_cnt   TYPE i,        " of those, the ones the Packing List will offer
             match_wt    TYPE p LENGTH 13 DECIMALS 3,
             need_batch  TYPE string,   " batches that pass every other rule
             other_lgort TYPE string,
             other_size  TYPE string,
             other_grade TYPE string,
             other_so    TYPE string,
             on_deliv    TYPE i,
             not_posted  TYPE i,
             hint        TYPE string,
           END OF ty_item.
    TYPES tt_item TYPE STANDARD TABLE OF ty_item WITH EMPTY KEY.

    TYPES: BEGIN OF ty_batch,
             vbeln TYPE vbeln_va,
             posnr TYPE posnr_va,
             charg TYPE charg_d,
           END OF ty_batch.
    TYPES tt_batch TYPE STANDARD TABLE OF ty_batch WITH EMPTY KEY.

    " Every item of the order with the verdict per rule.
    CLASS-METHODS check_order
      IMPORTING
        !iv_vbeln       TYPE vbeln_va
      RETURNING
        VALUE(rt_items) TYPE tt_item.

    " The batches the order names today (ZVBAP_BATCH).
    CLASS-METHODS get_batches
      IMPORTING
        !iv_vbeln         TYPE vbeln_va
      RETURNING
        VALUE(rt_batches) TYPE tt_batch.

    " Name a batch on an item - the row the VA02 item screen would write.
    " Refuses an item that does not exist, is rejected, or whose material
    " has no packed stock of that batch at the item's plant.
    CLASS-METHODS assign_batch
      IMPORTING
        !iv_vbeln TYPE vbeln_va
        !iv_posnr TYPE posnr_va
        !iv_charg TYPE charg_d
        !iv_user  TYPE csequence OPTIONAL   " app user (Scan Suite login), for the log
      EXPORTING
        !ev_error TYPE string.

    CLASS-METHODS remove_batch
      IMPORTING
        !iv_vbeln TYPE vbeln_va
        !iv_posnr TYPE posnr_va
        !iv_charg TYPE charg_d
        !iv_user  TYPE csequence OPTIONAL
      EXPORTING
        !ev_error TYPE string.

  PRIVATE SECTION.

    " One ZPP_PACK row of a box. A box can carry SEVERAL - on KSD box
    " 9960000001 has a JOB01/IA/01 row and a TEST1/00/05 row - and the
    " report reads them all (its SELECT is by box number with the size and
    " grade sets in the WHERE), so the box is offered as soon as ANY row
    " passes. The check has to look at every row too, or it fails a box
    " on the wrong row and disagrees with the Packing List.
    TYPES: BEGIN OF ty_pk,
             mergno TYPE zpp_pack-mergno,
             psize  TYPE zpp_pack-psize,
             grade  TYPE zpp_pack-grade,
             ptype  TYPE zpp_pack-ptype,
             so     TYPE zpp_pack-vbeln,
             netwt  TYPE zpp_pack-netwt,
             posted TYPE abap_bool,
           END OF ty_pk.
    TYPES tt_pk TYPE STANDARD TABLE OF ty_pk WITH EMPTY KEY.

    TYPES: BEGIN OF ty_hu,
             venum  TYPE venum,
             exidv  TYPE exidv,
             vpobj  TYPE vpobj,
             uevel  TYPE uevel,
             lgort  TYPE lgort_d,
             charg  TYPE charg_d,
             boxno  TYPE zpp_pack-boxno,
             packs  TYPE tt_pk,   " the row whose MERGNO is the HU batch comes first
           END OF ty_hu.
    TYPES tt_hu TYPE STANDARD TABLE OF ty_hu WITH EMPTY KEY.

    TYPES: BEGIN OF ty_count,
             val TYPE c LENGTH 10,
             cnt TYPE i,
             wt  TYPE p LENGTH 13 DECIMALS 3,
           END OF ty_count.
    TYPES tt_count TYPE SORTED TABLE OF ty_count WITH UNIQUE KEY val.

    TYPES ty_val TYPE c LENGTH 10.
    TYPES tt_val TYPE STANDARD TABLE OF ty_val WITH DEFAULT KEY.

    CLASS-METHODS read_hus
      IMPORTING
        !iv_matnr    TYPE matnr
        !iv_werks    TYPE werks_d
      RETURNING
        VALUE(rt_hu) TYPE tt_hu.

    CLASS-METHODS count_text
      IMPORTING
        !it_count      TYPE tt_count
        !iv_with_wt    TYPE abap_bool DEFAULT abap_false
      RETURNING
        VALUE(rv_text) TYPE string.

    CLASS-METHODS add_count
      IMPORTING
        !iv_val  TYPE clike
        !iv_wt   TYPE zpp_pack-netwt
      CHANGING
        !ct      TYPE tt_count.

    " One ZSOL_SOBATCH_LOG row, in the caller's LUW (the caller commits).
    CLASS-METHODS write_log
      IMPORTING
        !iv_vbeln  TYPE vbeln_va
        !iv_posnr  TYPE posnr_va
        !iv_charg  TYPE charg_d
        !iv_action TYPE zsol_sobatch_log-action
        !iv_user   TYPE csequence
        !iv_note   TYPE csequence OPTIONAL.

ENDCLASS.



CLASS zcl_zsol_so_boxcheck IMPLEMENTATION.


  METHOD get_batches.
    SELECT vbeln, posnr, charg FROM zvbap_batch
      WHERE vbeln = @iv_vbeln
      ORDER BY posnr, charg
      INTO CORRESPONDING FIELDS OF TABLE @rt_batches.
  ENDMETHOD.


  METHOD add_count.
    DATA lv_val TYPE c LENGTH 10.
    lv_val = iv_val.
    IF lv_val IS INITIAL.
      lv_val = '(blank)'.
    ENDIF.
    READ TABLE ct ASSIGNING FIELD-SYMBOL(<ls>) WITH TABLE KEY val = lv_val.
    IF sy-subrc <> 0.
      INSERT VALUE #( val = lv_val ) INTO TABLE ct ASSIGNING <ls>.
    ENDIF.
    <ls>-cnt = <ls>-cnt + 1.
    <ls>-wt  = <ls>-wt + iv_wt.
  ENDMETHOD.


  METHOD count_text.
    " "DFGT×20; UDL1×3" - biggest first, at most six values, so the
    " handheld gets one readable line rather than a catalogue.
    DATA lt TYPE STANDARD TABLE OF ty_count WITH EMPTY KEY.
    DATA lv_n TYPE i.
    lt = it_count.
    SORT lt BY cnt DESCENDING val.
    LOOP AT lt INTO DATA(ls).
      lv_n = lv_n + 1.
      IF lv_n > 6.
        rv_text = rv_text && |; +{ lines( lt ) - 6 } more|.
        EXIT.
      ENDIF.
      IF rv_text IS NOT INITIAL.
        rv_text = rv_text && `; `.
      ENDIF.
      rv_text = rv_text && |{ ls-val }×{ ls-cnt }|.
      IF iv_with_wt = abap_true.
        rv_text = rv_text && | ({ ls-wt NUMBER = RAW } KG)|.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.


  METHOD read_hus.

    " Packed stock of one material at one plant, as the Packing List sees
    " it: VEPO (material, plant, location, batch) joined to VEKP (status,
    " object, nesting) - the same bound ZRPT_SALES_SCAN puts on its read,
    " so this never walks the whole of VEPO - then the ZPP_PACK row by box
    " number, which is EXIDV without its leading zeros.
    DATA lv_boxno TYPE zpp_pack-boxno.

    SELECT a~venum, a~lgort, a~charg, c~exidv, c~vpobj, c~uevel
      FROM vepo AS a
      INNER JOIN vekp AS c ON c~venum = a~venum
      WHERE a~matnr = @iv_matnr
        AND a~werks = @iv_werks
        AND ( c~vpobj = '01' OR c~vpobj = '12' )
        AND ( c~status = '0020' OR c~status = '0030' )
      INTO TABLE @DATA(lt_vepo)
      UP TO 20000 ROWS.

    IF lt_vepo IS INITIAL.
      RETURN.
    ENDIF.

    SORT lt_vepo BY venum.
    DELETE ADJACENT DUPLICATES FROM lt_vepo COMPARING venum.

    LOOP AT lt_vepo INTO DATA(ls_v).
      APPEND INITIAL LINE TO rt_hu ASSIGNING FIELD-SYMBOL(<ls_hu>).
      <ls_hu>-venum = ls_v-venum.
      <ls_hu>-exidv = ls_v-exidv.
      <ls_hu>-vpobj = ls_v-vpobj.
      <ls_hu>-uevel = ls_v-uevel.
      <ls_hu>-lgort = ls_v-lgort.
      <ls_hu>-charg = ls_v-charg.
      CALL FUNCTION 'CONVERSION_EXIT_ALPHA_OUTPUT'
        EXPORTING
          input  = ls_v-exidv
        IMPORTING
          output = lv_boxno.
      <ls_hu>-boxno = lv_boxno.
    ENDLOOP.

    SELECT boxno, mergno, psize, grade, ptype, vbeln, netwt, hupost, repack, delind
      FROM zpp_pack
      FOR ALL ENTRIES IN @rt_hu
      WHERE boxno = @rt_hu-boxno
      INTO TABLE @DATA(lt_pack).
    SORT lt_pack BY boxno.

    LOOP AT rt_hu ASSIGNING <ls_hu>.
      READ TABLE lt_pack TRANSPORTING NO FIELDS WITH KEY boxno = <ls_hu>-boxno BINARY SEARCH.
      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.
      LOOP AT lt_pack INTO DATA(ls_p) FROM sy-tabix.
        IF ls_p-boxno <> <ls_hu>-boxno.
          EXIT.
        ENDIF.
        DATA(ls_pk) = VALUE ty_pk( mergno = ls_p-mergno psize = ls_p-psize grade = ls_p-grade
                                   ptype  = ls_p-ptype  so    = ls_p-vbeln netwt = ls_p-netwt ).
        IF ls_p-delind IS INITIAL AND ( ls_p-hupost IS NOT INITIAL OR ls_p-repack IS NOT INITIAL ).
          ls_pk-posted = abap_true.
        ENDIF.
        " The row that belongs to this HU's batch first: when no row
        " passes, that is the one whose values are reported.
        IF ls_pk-mergno = <ls_hu>-charg AND ls_pk-mergno IS NOT INITIAL.
          INSERT ls_pk INTO <ls_hu>-packs INDEX 1.
        ELSE.
          APPEND ls_pk TO <ls_hu>-packs.
        ENDIF.
      ENDLOOP.
    ENDLOOP.

    " A handling unit with no packing record is not a carton this process
    " knows; it would never reach the Packing List either.
    DELETE rt_hu WHERE packs IS INITIAL.

  ENDMETHOD.


  METHOD check_order.

    DATA: lt_sizes   TYPE tt_val,
          lt_grades  TYPE tt_val,
          lt_batches TYPE tt_batch,
          lt_item_b  TYPE tt_val,
          lt_hu      TYPE tt_hu,
          lt_c_lgort TYPE tt_count,
          lt_c_batch TYPE tt_count,
          lt_c_size  TYPE tt_count,
          lt_c_grade TYPE tt_count,
          lt_c_so    TYPE tt_count,
          lv_ok      TYPE abap_bool,
          lv_bat_ok  TYPE abap_bool,
          lv_lg_ok   TYPE abap_bool,
          lv_sz_ok   TYPE abap_bool,
          lv_gr_ok   TYPE abap_bool,
          lv_fr_ok   TYPE abap_bool,
          lv_nb_done TYPE abap_bool,
          ls_pk_rep  TYPE ty_pk.

    SELECT vbeln, posnr, matnr, arktx, werks, lgort, charg, kwmeng, vrkme, abgru,
           zzsize, zzsiz1, zzsiz2, zzgrade, zzgrad1, zzgrad2
      FROM vbap
      WHERE vbeln = @iv_vbeln
      ORDER BY posnr
      INTO CORRESPONDING FIELDS OF TABLE @rt_items.

    IF rt_items IS INITIAL.
      RETURN.
    ENDIF.

    " Delivered so far, the way DATA_RETRIEVAL sums it.
    SELECT vgbel, vgpos, SUM( lfimg ) AS lfimg
      FROM lips
      WHERE vgbel = @iv_vbeln
      GROUP BY vgbel, vgpos
      INTO TABLE @DATA(lt_lips).
    SORT lt_lips BY vgpos.

    " Sizes and grades are collected over the WHOLE order, as the report
    " does (GET_DATA fills S_SIZE / S_GRADE from every GT_FINAL row).
    LOOP AT rt_items INTO DATA(ls_i).
      IF ls_i-zzsize  IS NOT INITIAL. APPEND ls_i-zzsize  TO lt_sizes.  ENDIF.
      IF ls_i-zzsiz1  IS NOT INITIAL. APPEND ls_i-zzsiz1  TO lt_sizes.  ENDIF.
      IF ls_i-zzsiz2  IS NOT INITIAL. APPEND ls_i-zzsiz2  TO lt_sizes.  ENDIF.
      IF ls_i-zzgrade IS NOT INITIAL. APPEND ls_i-zzgrade TO lt_grades. ENDIF.
      IF ls_i-zzgrad1 IS NOT INITIAL. APPEND ls_i-zzgrad1 TO lt_grades. ENDIF.
      IF ls_i-zzgrad2 IS NOT INITIAL. APPEND ls_i-zzgrad2 TO lt_grades. ENDIF.
    ENDLOOP.
    SORT lt_sizes.  DELETE ADJACENT DUPLICATES FROM lt_sizes.
    SORT lt_grades. DELETE ADJACENT DUPLICATES FROM lt_grades.

    lt_batches = get_batches( iv_vbeln ).

    LOOP AT rt_items ASSIGNING FIELD-SYMBOL(<ls_item>).

      READ TABLE lt_lips INTO DATA(ls_lips) WITH KEY vgpos = <ls_item>-posnr BINARY SEARCH.
      IF sy-subrc = 0.
        <ls_item>-dis_qty = ls_lips-lfimg.
      ENDIF.
      <ls_item>-open_qty = <ls_item>-kwmeng - <ls_item>-dis_qty.
      IF <ls_item>-open_qty < 0.
        <ls_item>-open_qty = 0.
      ENDIF.

      " The batches this item names. ZVBAP_BATCH rows win; the report's
      " ZVBAP_BATCH read keys on the ORDER and takes the first item's
      " material for every batch, so a batch assigned on any item of a
      " single-material order behaves as assigned on all of them - shown
      " here per item, which is what the VA02 screen shows too.
      CLEAR lt_item_b.
      LOOP AT lt_batches INTO DATA(ls_b) WHERE posnr = <ls_item>-posnr.
        APPEND ls_b-charg TO lt_item_b.
      ENDLOOP.
      IF lt_item_b IS NOT INITIAL.
        <ls_item>-batch_src = 'A'.
      ELSEIF <ls_item>-charg IS NOT INITIAL.
        APPEND <ls_item>-charg TO lt_item_b.
        <ls_item>-batch_src = 'C'.
      ENDIF.
      LOOP AT lt_item_b INTO DATA(lv_b).
        IF <ls_item>-so_batches IS NOT INITIAL.
          <ls_item>-so_batches = <ls_item>-so_batches && `; `.
        ENDIF.
        <ls_item>-so_batches = <ls_item>-so_batches && lv_b.
      ENDLOOP.

      lt_hu = read_hus( iv_matnr = <ls_item>-matnr iv_werks = <ls_item>-werks ).
      <ls_item>-cand_cnt = lines( lt_hu ).

      CLEAR: lt_c_lgort, lt_c_batch, lt_c_size, lt_c_grade, lt_c_so.
      LOOP AT lt_hu INTO DATA(ls_hu).

        IF ls_hu-vpobj = '01'.
          <ls_item>-on_deliv = <ls_item>-on_deliv + 1.
          CONTINUE.
        ENDIF.

        " Location and batch are properties of the HU; size, grade, the
        " stamped order and the posting flag come from each ZPP_PACK row.
        " The box passes as soon as one posted row passes.
        lv_lg_ok = xsdbool( ls_hu-lgort = <ls_item>-lgort ).
        IF lt_item_b IS INITIAL.
          lv_bat_ok = xsdbool( ls_hu-charg IS INITIAL ).
        ELSE.
          lv_bat_ok = xsdbool( line_exists( lt_item_b[ table_line = ls_hu-charg ] ) ).
        ENDIF.

        CLEAR ls_pk_rep.
        lv_ok = abap_false.
        LOOP AT ls_hu-packs INTO DATA(ls_pk) WHERE posted = abap_true.
          IF ls_pk_rep IS INITIAL.
            ls_pk_rep = ls_pk.
          ENDIF.
          lv_sz_ok = xsdbool( lt_sizes  IS INITIAL OR line_exists( lt_sizes[ table_line = ls_pk-psize ] ) ).
          lv_gr_ok = xsdbool( lt_grades IS INITIAL OR line_exists( lt_grades[ table_line = ls_pk-grade ] ) ).
          lv_fr_ok = xsdbool( ls_pk-so IS INITIAL ).
          IF lv_lg_ok = abap_true AND lv_bat_ok = abap_true AND lv_sz_ok = abap_true
             AND lv_gr_ok = abap_true AND lv_fr_ok = abap_true.
            lv_ok = abap_true.
            EXIT.
          ENDIF.
          " A batch that passes every other rule on this row: naming it on
          " the item is all that stands between the box and the Packing
          " List. Counted once per box.
          IF lv_bat_ok = abap_false AND lv_lg_ok = abap_true AND lv_sz_ok = abap_true
             AND lv_gr_ok = abap_true AND lv_fr_ok = abap_true AND lv_nb_done = abap_false.
            add_count( EXPORTING iv_val = ls_hu-charg iv_wt = ls_pk-netwt CHANGING ct = lt_c_batch ).
            lv_nb_done = abap_true.
          ENDIF.
        ENDLOOP.
        lv_nb_done = abap_false.

        IF lv_ok = abap_true.
          <ls_item>-match_cnt = <ls_item>-match_cnt + 1.
          <ls_item>-match_wt  = <ls_item>-match_wt + ls_pk-netwt.
          CONTINUE.
        ENDIF.

        IF ls_pk_rep IS INITIAL.
          <ls_item>-not_posted = <ls_item>-not_posted + 1.
          CONTINUE.
        ENDIF.

        " One HU can fail several rules; each failure is counted under
        " its own heading, on the row that belongs to the HU's batch (or
        " the first posted one), so the operator sees every reason at once.
        IF lv_lg_ok = abap_false.
          add_count( EXPORTING iv_val = ls_hu-lgort iv_wt = ls_pk_rep-netwt CHANGING ct = lt_c_lgort ).
        ENDIF.
        IF lt_sizes IS NOT INITIAL AND NOT line_exists( lt_sizes[ table_line = ls_pk_rep-psize ] ).
          add_count( EXPORTING iv_val = ls_pk_rep-psize iv_wt = ls_pk_rep-netwt CHANGING ct = lt_c_size ).
        ENDIF.
        IF lt_grades IS NOT INITIAL AND NOT line_exists( lt_grades[ table_line = ls_pk_rep-grade ] ).
          add_count( EXPORTING iv_val = ls_pk_rep-grade iv_wt = ls_pk_rep-netwt CHANGING ct = lt_c_grade ).
        ENDIF.
        IF ls_pk_rep-so IS NOT INITIAL.
          add_count( EXPORTING iv_val = |{ ls_pk_rep-so ALPHA = OUT }| iv_wt = ls_pk_rep-netwt CHANGING ct = lt_c_so ).
        ENDIF.
      ENDLOOP.

      <ls_item>-need_batch  = count_text( it_count = lt_c_batch iv_with_wt = abap_true ).
      <ls_item>-other_lgort = count_text( lt_c_lgort ).
      <ls_item>-other_size  = count_text( lt_c_size ).
      <ls_item>-other_grade = count_text( lt_c_grade ).
      <ls_item>-other_so    = count_text( lt_c_so ).

      " One sentence the operator can act on.
      IF <ls_item>-abgru IS NOT INITIAL.
        <ls_item>-hint = |Item is rejected (reason { <ls_item>-abgru }) - it is not picked|.
      ELSEIF <ls_item>-kwmeng <= 0.
        <ls_item>-hint = 'Item has no order quantity - nothing to pick'.
      ELSEIF <ls_item>-open_qty <= 0.
        <ls_item>-hint = 'Item is fully delivered'.
      ELSEIF <ls_item>-match_cnt > 0.
        <ls_item>-hint = |{ <ls_item>-match_cnt } HU(s) can be picked|.
      ELSEIF <ls_item>-cand_cnt = 0.
        <ls_item>-hint = |No packed stock of { <ls_item>-matnr } in plant { <ls_item>-werks }|.
      ELSEIF lt_c_batch IS NOT INITIAL.
        IF lt_item_b IS INITIAL.
          <ls_item>-hint = 'Order names no batch; the packed stock carries batches - assign one of the batches listed'.
        ELSEIF <ls_item>-batch_src = 'C'.
          " A single batch on the item itself (VBAP-CHARG). VA02 refuses a
          " batch list on such an item, so the card must not offer one.
          <ls_item>-hint = |No packed stock carries the item's batch { <ls_item>-charg } - change the batch on the order item (VA02) or pick from the lots listed after that|.
        ELSE.
          <ls_item>-hint = 'None of the packed stock carries the batches assigned to the item - assign one of the batches listed'.
        ENDIF.
      ELSEIF lt_c_lgort IS NOT INITIAL AND lt_c_size IS INITIAL AND lt_c_grade IS INITIAL AND lt_c_so IS INITIAL.
        <ls_item>-hint = |Stock is in another storage location - order item says { <ls_item>-lgort }|.
      ELSEIF lt_c_size IS NOT INITIAL OR lt_c_grade IS NOT INITIAL.
        <ls_item>-hint = 'Packed stock has a different size / grade from the order'.
      ELSEIF lt_c_so IS NOT INITIAL.
        <ls_item>-hint = 'All packed stock is already reserved by other sales orders'.
      ELSEIF <ls_item>-on_deliv > 0.
        <ls_item>-hint = 'All packed stock is already on a delivery'.
      ELSEIF <ls_item>-not_posted > 0.
        <ls_item>-hint = 'Packing records exist but are not posted (HU / GR pending)'.
      ELSE.
        <ls_item>-hint = 'No handling unit passes every rule - see the counts'.
      ENDIF.

    ENDLOOP.

  ENDMETHOD.


  METHOD write_log.

    " A = assigned, R = removed. SOURCE says which program wrote the row;
    " today only the Scan Suite does ('SCAN'), VA02's batch tab does not
    " log, so absence of a row means "changed in SAP directly".
    DATA ls_log TYPE zsol_sobatch_log.

    TRY.
        ls_log-logid = cl_system_uuid=>create_uuid_x16_static( ).
      CATCH cx_uuid_error.
        RETURN.   " no id, no row - never let the log stop the write itself
    ENDTRY.
    ls_log-mandt    = sy-mandt.
    ls_log-vbeln    = iv_vbeln.
    ls_log-posnr    = iv_posnr.
    ls_log-charg    = iv_charg.
    ls_log-action   = iv_action.
    ls_log-app_user = iv_user.
    ls_log-sap_user = sy-uname.
    ls_log-log_date = sy-datum.
    ls_log-log_time = sy-uzeit.
    ls_log-source   = 'SCAN'.
    ls_log-note     = iv_note.
    INSERT zsol_sobatch_log FROM @ls_log.

  ENDMETHOD.


  METHOD assign_batch.

    DATA ls_row TYPE zvbap_batch.

    CLEAR ev_error.

    SELECT SINGLE matnr, werks, abgru, charg FROM vbap
      WHERE vbeln = @iv_vbeln AND posnr = @iv_posnr
      INTO @DATA(ls_item).
    IF sy-subrc <> 0.
      ev_error = |Item { iv_posnr ALPHA = OUT } of order { iv_vbeln ALPHA = OUT } does not exist|.
      RETURN.
    ENDIF.
    IF ls_item-abgru IS NOT INITIAL.
      ev_error = |Item { iv_posnr ALPHA = OUT } is rejected|.
      RETURN.
    ENDIF.
    " The same rule VA01/VA02 enforce (MV45AFZZ: "Single Batch And
    " Multiple Batches are not Allowed at Single line item"): an item
    " carries EITHER one batch in VBAP-CHARG OR a batch list in
    " ZVBAP_BATCH. Writing a list row next to a single batch would make
    " a document VA02 refuses to save.
    IF ls_item-charg IS NOT INITIAL.
      ev_error = |Item { iv_posnr ALPHA = OUT } already carries batch { ls_item-charg } as its single batch - change it on the order item (VA02) instead|.
      RETURN.
    ENDIF.
    IF iv_charg IS INITIAL.
      ev_error = 'Choose a batch'.
      RETURN.
    ENDIF.

    " Only a batch that actually exists as packed stock of this material
    " at this plant. Typing a batch nobody has would not make boxes
    " appear and would hide the real reason.
    SELECT SINGLE a~venum FROM vepo AS a
      INNER JOIN vekp AS c ON c~venum = a~venum
      WHERE a~matnr = @ls_item-matnr
        AND a~werks = @ls_item-werks
        AND a~charg = @iv_charg
        AND ( c~vpobj = '01' OR c~vpobj = '12' )
        AND ( c~status = '0020' OR c~status = '0030' )
      INTO @DATA(lv_venum).
    IF sy-subrc <> 0.
      ev_error = |No packed stock of { ls_item-matnr } with batch { iv_charg } in plant { ls_item-werks }|.
      RETURN.
    ENDIF.

    ls_row-mandt = sy-mandt.
    ls_row-vbeln = iv_vbeln.
    ls_row-posnr = iv_posnr.
    ls_row-charg = iv_charg.
    " Key-only table: INSERT, and a row that is already there is not an
    " error - the batch is assigned either way.
    INSERT zvbap_batch FROM @ls_row.
    IF sy-subrc = 0.
      write_log( iv_vbeln = iv_vbeln iv_posnr = iv_posnr iv_charg = iv_charg
                 iv_action = 'A' iv_user = iv_user
                 iv_note = |{ ls_item-matnr } plant { ls_item-werks }| ).
    ELSEIF sy-subrc <> 4.
      ev_error = 'The batch could not be saved'.
      RETURN.
    ENDIF.
    COMMIT WORK.

  ENDMETHOD.


  METHOD remove_batch.

    CLEAR ev_error.

    DELETE FROM zvbap_batch
      WHERE vbeln = @iv_vbeln AND posnr = @iv_posnr AND charg = @iv_charg.
    IF sy-subrc <> 0.
      ev_error = |Batch { iv_charg } is not assigned to item { iv_posnr ALPHA = OUT }|.
      RETURN.
    ENDIF.
    write_log( iv_vbeln = iv_vbeln iv_posnr = iv_posnr iv_charg = iv_charg
               iv_action = 'R' iv_user = iv_user ).
    COMMIT WORK.

  ENDMETHOD.

ENDCLASS.
