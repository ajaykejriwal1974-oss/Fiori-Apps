CLASS zcl_zsol_prod_jobcard DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

* ----------------------------------------------------------------------
* Scan Suite - dyeing batches and job cards (06.09.2026)
*
* The dyeing floor's paper trail in KSD is three legacy tables and two
* module pools:
*
*   ZPP_BATCHN   a WIP batch, drawn from a released production order by
*                ZBATCH01N (SAPMZ_PP_BATCHN): number from range ZPP_BTH via
*                ZPP_BTNUM (plant / order type / year), an SAP batch of the
*                dyed material raised with BAPI_BATCH_CREATE.
*   ZPP_JOBN     a job card: the batch (JOBNO = BATCHNO, all 131,340 rows),
*                the schedule it serves (ZPP_SCHEDULEN) and the dyeing and
*                winding work centres. ZJOB01N (SAPMZ_PP_JOB_CARDN) writes it
*                and stamps ZPP_BATCHN-ASSIGNED.
*   ZPP_SCHEDULEN what was promised to whom: sales order item, dyed
*                material, shade, quantity, dyeing date.
*
* The Fiori rewrites of both screens exist as RAP business objects -
* ZI_WIP_BATCH_MGMT (static action createBatch / closeBatches /
* reopenBatches, unmanaged, ZKGPL_FIORI) and ZI_Job (managed, additional
* save) - and this class WRITES THROUGH THEM with EML rather than copying
* their logic. What ZBATCH01N refuses to save on, createBatch refuses too;
* what ZJOB01N stamps on the batch, ZI_Job's additional save stamps. The
* authority object Z_WIPBATCH inside createBatch is checked against the
* SAP user of the request, which for the Scan Suite is the shared service
* account - it needs the ZKIPL_PRODUCTION role (or Z_WIPBATCH for the
* dyeing plants) on every system the suite runs on. The per-person
* boundary is the Scan Suite grant: WIPBATCH and JOBCARD screens, plus the
* plant.
*
* ZI_Job carries no validations of its own (the Fiori Job Master saves any
* batch, any schedule, any work centre). The refusals ZJOB01N makes are
* applied here before the EML call, and separately added to ZI_Job as a
* validation so the Fiori app stops accepting them too.
*
* Reads feed the two Scan Suite screens and the printed job card:
* orders that can take a batch, the batches of an order, open schedules
* for a dyed material, the plant's work centres, job cards with every
* field the card prints (from ZI_JobCardReport, the report's own view)
* and the dyeing recipe behind a card (ZI_JobCardRecipe).
*
* Every write also leaves a row in ZSOL_SOBATCH_LOG carrying the Scan
* Suite login - ZPP_BATCHN and ZPP_JOBN record only the SAP user, which
* for this app is always the service account.
*
* 07.09.2026: an "open" schedule (LIST_SCHEDULES, IV_OPEN_ONLY) is one
* not marked complete AND with something left to batch. On plant 2002
* the newest schedules were all over-batched ("-35.2 KG left") and filled
* the list, hiding the ones still open. A schedule asked for by number is
* returned whatever its state, so a typed or scanned number still works.
* ----------------------------------------------------------------------

  PUBLIC SECTION.

    TYPES tt_order   TYPE zcl_zsol_scan_read_mpc=>tt_prod_order.
    TYPES tt_batch   TYPE zcl_zsol_scan_read_mpc=>tt_wip_batch.
    TYPES tt_jobcard TYPE zcl_zsol_scan_read_mpc=>tt_jobcard.
    TYPES tt_recipe  TYPE zcl_zsol_scan_read_mpc=>tt_jc_recipe.
    TYPES tt_sched   TYPE zcl_zsol_scan_read_mpc=>tt_schedule.
    TYPES tt_wc      TYPE zcl_zsol_scan_read_mpc=>tt_workcenter.

    " Released, open KID orders of a plant that can still take a batch,
    " newest first - or one order by number, with the reason it cannot.
    CLASS-METHODS list_orders
      IMPORTING
        !iv_werks        TYPE werks_d
        !iv_aufnr        TYPE aufnr OPTIONAL
      RETURNING
        VALUE(rt_orders) TYPE tt_order.

    " Batches of a plant: one order's, or the last IV_DAYS days, open only
    " on request. Each row carries its job card when one exists.
    CLASS-METHODS list_batches
      IMPORTING
        !iv_werks         TYPE werks_d
        !iv_aufnr         TYPE aufnr OPTIONAL
        !iv_batchno       TYPE charg_d OPTIONAL
        !iv_days          TYPE i DEFAULT 30
        !iv_open_only     TYPE abap_bool DEFAULT abap_false
      RETURNING
        VALUE(rt_batches) TYPE tt_batch.

    " Draw a batch from an order - ZI_WIP_BATCH_MGMT~createBatch.
    CLASS-METHODS create_batch
      IMPORTING
        !is_new     TYPE zcl_zsol_scan_read_mpc=>ts_wip_batch
        !iv_user    TYPE csequence OPTIONAL
      EXPORTING
        !ev_batchno TYPE charg_d
        !ev_error   TYPE string.

    " Close or reopen - ZI_WIP_BATCH_MGMT~closeBatches / reopenBatches.
    CLASS-METHODS close_batch
      IMPORTING
        !iv_batchno TYPE charg_d
        !iv_gjahr   TYPE gjahr
        !iv_reopen  TYPE abap_bool DEFAULT abap_false
        !iv_reason  TYPE csequence OPTIONAL
        !iv_user    TYPE csequence OPTIONAL
      EXPORTING
        !ev_message TYPE string
        !ev_error   TYPE string.

    " Schedules of a plant for one dyed material (the batch's DYE_CODE),
    " not deleted; open unless asked for all - open meaning not marked
    " complete and with quantity still to batch. With what is batched so
    " far. One schedule by number is returned whatever its state.
    CLASS-METHODS list_schedules
      IMPORTING
        !iv_werks       TYPE werks_d
        !iv_matnr       TYPE matnr OPTIONAL
        !iv_schno       TYPE zpp_schedulen-schno OPTIONAL
        !iv_open_only   TYPE abap_bool DEFAULT abap_true
      RETURNING
        VALUE(rt_sched) TYPE tt_sched.

    " Work centres of a plant, dyeing first, most used first.
    CLASS-METHODS list_workcenters
      IMPORTING
        !iv_werks    TYPE werks_d
      RETURNING
        VALUE(rt_wc) TYPE tt_wc.

    " Job cards with everything the printed card shows.
    CLASS-METHODS list_jobcards
      IMPORTING
        !iv_werks      TYPE werks_d
        !iv_jobno      TYPE charg_d OPTIONAL
        !iv_days       TYPE i DEFAULT 30
      RETURNING
        VALUE(rt_jobs) TYPE tt_jobcard.

    " The dyeing recipe behind a job card.
    CLASS-METHODS get_recipe
      IMPORTING
        !iv_jobno        TYPE charg_d
      RETURNING
        VALUE(rt_recipe) TYPE tt_recipe.

    " Write a job card for a free batch - ZI_Job create, after the checks
    " ZJOB01N makes.
    CLASS-METHODS create_jobcard
      IMPORTING
        !iv_batchno   TYPE charg_d
        !iv_schno     TYPE zpp_schedulen-schno
        !iv_dye_arbpl TYPE arbpl
        !iv_win_arbpl TYPE arbpl OPTIONAL
        !iv_user      TYPE csequence OPTIONAL
      EXPORTING
        !ev_jobno     TYPE charg_d
        !ev_error     TYPE string.

  PRIVATE SECTION.

    CLASS-METHODS date_out
      IMPORTING
        !iv_date       TYPE d
      RETURNING
        VALUE(rv_text) TYPE string.

    CLASS-METHODS qty_out
      IMPORTING
        !iv_qty        TYPE numeric
      RETURNING
        VALUE(rv_text) TYPE string.

    CLASS-METHODS aufnr_out
      IMPORTING
        !iv_aufnr      TYPE aufnr
      RETURNING
        VALUE(rv_text) TYPE string.

    CLASS-METHODS customer_of
      IMPORTING
        !iv_vbeln      TYPE vbeln_va
      RETURNING
        VALUE(rv_name) TYPE string.

    CLASS-METHODS wc_text
      IMPORTING
        !iv_werks      TYPE werks_d
        !iv_arbpl      TYPE arbpl
      RETURNING
        VALUE(rv_text) TYPE string.

    " Messages of a failed EML call as one line.
    CLASS-METHODS reported_text
      IMPORTING
        !it_msg        TYPE INDEX TABLE
      RETURNING
        VALUE(rv_text) TYPE string.

    CLASS-METHODS write_log
      IMPORTING
        !iv_vbeln  TYPE vbeln_va OPTIONAL
        !iv_posnr  TYPE posnr_va OPTIONAL
        !iv_charg  TYPE charg_d
        !iv_action TYPE zsol_sobatch_log-action
        !iv_user   TYPE csequence
        !iv_note   TYPE csequence OPTIONAL.

ENDCLASS.



CLASS zcl_zsol_prod_jobcard IMPLEMENTATION.


  METHOD date_out.
    IF iv_date IS NOT INITIAL.
      rv_text = iv_date.
    ENDIF.
  ENDMETHOD.


  METHOD qty_out.
    rv_text = |{ iv_qty NUMBER = RAW }|.
    CONDENSE rv_text NO-GAPS.
  ENDMETHOD.


  METHOD aufnr_out.
    rv_text = |{ iv_aufnr ALPHA = OUT }|.
    CONDENSE rv_text NO-GAPS.
  ENDMETHOD.


  METHOD customer_of.
    " Sold-to name of the schedule's sales order - the one line on the
    " card the floor recognises an order by.
    IF iv_vbeln IS INITIAL.
      RETURN.
    ENDIF.
    SELECT SINGLE k~name1 FROM vbak AS v
      INNER JOIN kna1 AS k ON k~kunnr = v~kunnr
      WHERE v~vbeln = @iv_vbeln
      INTO @rv_name.
  ENDMETHOD.


  METHOD wc_text.
    IF iv_arbpl IS INITIAL.
      RETURN.
    ENDIF.
    SELECT SINGLE t~ktext FROM crhd AS h
      INNER JOIN crtx AS t ON t~objty = h~objty AND t~objid = h~objid AND t~spras = @sy-langu
      WHERE h~objty = 'A' AND h~werks = @iv_werks AND h~arbpl = @iv_arbpl
      INTO @rv_text.
  ENDMETHOD.


  METHOD reported_text.
    " Every REPORTED line of an EML response carries %msg; anything with
    " one is joined, so the operator sees the RAP's own words.
    FIELD-SYMBOLS <ls> TYPE any.
    FIELD-SYMBOLS <lo> TYPE REF TO if_abap_behv_message.
    LOOP AT it_msg ASSIGNING <ls>.
      ASSIGN COMPONENT '%MSG' OF STRUCTURE <ls> TO <lo>.
      IF sy-subrc = 0 AND <lo> IS BOUND.
        DATA(lv_t) = <lo>->if_message~get_text( ).
        IF lv_t IS NOT INITIAL.
          rv_text = COND #( WHEN rv_text IS INITIAL THEN lv_t ELSE |{ rv_text } { lv_t }| ).
        ENDIF.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.


  METHOD write_log.
    DATA ls_log TYPE zsol_sobatch_log.
    TRY.
        ls_log-logid = cl_system_uuid=>create_uuid_x16_static( ).
      CATCH cx_uuid_error.
        RETURN.
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


  METHOD list_orders.

    " The status test is the one createBatch applies: released (I0002),
    " and none of TECO / CLSD / DLFL active. Read on JEST rather than the
    " STATUS_TEXT_EDIT line the module pool parses, so it does not depend
    " on the language of the status text.
    DATA lr_aufnr TYPE RANGE OF aufnr.
    DATA ls_row   TYPE zcl_zsol_scan_read_mpc=>ts_prod_order.
    DATA lv_clabs TYPE mchb-clabs.

    IF iv_aufnr IS NOT INITIAL.
      lr_aufnr = VALUE #( ( sign = 'I' option = 'EQ' low = |{ iv_aufnr ALPHA = IN }| ) ).
    ENDIF.

    SELECT k~aufnr, k~werks, k~auart, k~erdat, k~objnr, p~matnr, p~psmng, p~amein
      FROM aufk AS k
      INNER JOIN afpo AS p ON p~aufnr = k~aufnr AND p~posnr = '0001'
      WHERE k~werks = @iv_werks
        AND k~autyp = '10'
        AND k~aufnr IN @lr_aufnr
      ORDER BY k~erdat DESCENDING, k~aufnr DESCENDING
      INTO TABLE @DATA(lt_ord)
      UP TO 300 ROWS.

    IF lt_ord IS INITIAL.
      RETURN.
    ENDIF.

    SELECT objnr, stat FROM jest
      FOR ALL ENTRIES IN @lt_ord
      WHERE objnr = @lt_ord-objnr
        AND inact = @space
        AND stat IN ( 'I0002', 'I0045', 'I0046', 'I0076' )
      INTO TABLE @DATA(lt_stat).
    SORT lt_stat BY objnr stat.

    " First component of each order is the grey yarn (RESB by RSPOS, as
    " GET_ORDER_DATA reads it); its batch is the lot the module pool
    " proposes.
    SELECT aufnr, rspos, matnr, charg FROM resb
      FOR ALL ENTRIES IN @lt_ord
      WHERE aufnr = @lt_ord-aufnr
        AND xloek = @space
      INTO TABLE @DATA(lt_resb).
    SORT lt_resb BY aufnr rspos.

    " Batches drawn so far, summed in ABAP - FOR ALL ENTRIES and GROUP BY
    " do not mix.
    TYPES: BEGIN OF ty_sum, aufnr TYPE aufnr, qty TYPE zpp_batchn-qty, cnt TYPE i, END OF ty_sum.
    DATA lt_sum TYPE SORTED TABLE OF ty_sum WITH UNIQUE KEY aufnr.
    SELECT aufnr, qty FROM zpp_batchn
      FOR ALL ENTRIES IN @lt_ord
      WHERE aufnr = @lt_ord-aufnr
        AND gjahr <> '0000'
        AND delind <> 'X'
      INTO TABLE @DATA(lt_bq).
    LOOP AT lt_bq INTO DATA(ls_bq).
      READ TABLE lt_sum ASSIGNING FIELD-SYMBOL(<ls_sum>) WITH TABLE KEY aufnr = ls_bq-aufnr.
      IF sy-subrc <> 0.
        INSERT VALUE #( aufnr = ls_bq-aufnr ) INTO TABLE lt_sum ASSIGNING <ls_sum>.
      ENDIF.
      <ls_sum>-qty = <ls_sum>-qty + ls_bq-qty.
      <ls_sum>-cnt = <ls_sum>-cnt + 1.
    ENDLOOP.

    SELECT matnr, maktx FROM makt
      FOR ALL ENTRIES IN @lt_ord
      WHERE matnr = @lt_ord-matnr AND spras = @sy-langu
      INTO TABLE @DATA(lt_makt).
    SORT lt_makt BY matnr.

    LOOP AT lt_ord INTO DATA(ls_o).
      CLEAR ls_row.
      ASSIGN ls_row TO FIELD-SYMBOL(<ls>).
      <ls>-aufnr = aufnr_out( ls_o-aufnr ).
      <ls>-werks = ls_o-werks.
      <ls>-auart = ls_o-auart.
      <ls>-erdat = date_out( ls_o-erdat ).
      <ls>-matnr = ls_o-matnr.
      <ls>-psmng = qty_out( ls_o-psmng ).
      <ls>-meins = ls_o-amein.
      READ TABLE lt_makt INTO DATA(ls_makt) WITH KEY matnr = ls_o-matnr BINARY SEARCH.
      IF sy-subrc = 0.
        <ls>-maktx = ls_makt-maktx.
      ENDIF.

      DATA(lv_rel)  = xsdbool( line_exists( lt_stat[ objnr = ls_o-objnr stat = 'I0002' ] ) ).
      DATA(lv_teco) = xsdbool( line_exists( lt_stat[ objnr = ls_o-objnr stat = 'I0045' ] ) ).
      DATA(lv_clsd) = xsdbool( line_exists( lt_stat[ objnr = ls_o-objnr stat = 'I0046' ] ) ).
      DATA(lv_dlfl) = xsdbool( line_exists( lt_stat[ objnr = ls_o-objnr stat = 'I0076' ] ) ).
      <ls>-status = COND #( WHEN lv_dlfl = abap_true THEN 'Deletion flag'
                            WHEN lv_clsd = abap_true THEN 'Closed'
                            WHEN lv_teco = abap_true THEN 'Technically complete'
                            WHEN lv_rel  = abap_true THEN 'Released'
                            ELSE 'Not released' ).

      READ TABLE lt_resb INTO DATA(ls_r) WITH KEY aufnr = ls_o-aufnr BINARY SEARCH.
      IF sy-subrc = 0.
        <ls>-grey_code = ls_r-matnr.
        <ls>-lotno     = ls_r-charg.
        SELECT SINGLE maktx FROM makt WHERE matnr = @ls_r-matnr AND spras = @sy-langu
          INTO @<ls>-grey_item.
        IF ls_r-charg IS NOT INITIAL.
          " Free stock of the lot where the module pool looks for it.
          CLEAR lv_clabs.
          SELECT SUM( clabs ) FROM mchb
            WHERE matnr = @ls_r-matnr AND werks = @iv_werks AND charg = @ls_r-charg
              AND ( lgort = 'DPR1' OR lgort = 'JWPR' )
            INTO @lv_clabs.
          <ls>-lot_qty = qty_out( lv_clabs ).
        ENDIF.
      ENDIF.

      READ TABLE lt_sum INTO DATA(ls_sum) WITH TABLE KEY aufnr = ls_o-aufnr.
      IF sy-subrc = 0.
        <ls>-tot_batch = qty_out( ls_sum-qty ).
        <ls>-batch_cnt = ls_sum-cnt.
        <ls>-open_qty  = qty_out( ls_o-psmng - ls_sum-qty ).
      ELSE.
        <ls>-tot_batch = '0'.
        <ls>-open_qty  = qty_out( ls_o-psmng ).
      ENDIF.

      " Can a batch be drawn today? Same tests as createBatch, in its order.
      IF lv_rel <> abap_true.
        <ls>-reason = 'Order not released'.
      ELSEIF lv_teco = abap_true OR lv_clsd = abap_true OR lv_dlfl = abap_true.
        <ls>-reason = 'Check Order Status'.
      ELSEIF <ls>-grey_code IS INITIAL.
        <ls>-reason = 'BOM not found'.
      ELSE.
        <ls>-can_create = abap_true.
      ENDIF.

      " The list is for picking an order to batch from; a single order is
      " reported whatever its state.
      IF iv_aufnr IS NOT INITIAL OR <ls>-can_create = abap_true.
        APPEND ls_row TO rt_orders.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.


  METHOD list_batches.

    DATA lr_aufnr  TYPE RANGE OF aufnr.
    DATA lr_batch  TYPE RANGE OF charg_d.
    DATA lr_erdat  TYPE RANGE OF erdat.
    DATA lr_closed TYPE RANGE OF zpp_batchn-closed.

    IF iv_aufnr IS NOT INITIAL.
      lr_aufnr = VALUE #( ( sign = 'I' option = 'EQ' low = |{ iv_aufnr ALPHA = IN }| ) ).
    ENDIF.
    IF iv_batchno IS NOT INITIAL.
      lr_batch = VALUE #( ( sign = 'I' option = 'EQ' low = iv_batchno ) ).
    ENDIF.
    " The day window applies to a browse; an order or a batch is asked for
    " by name and answered whatever its age.
    IF lr_aufnr IS INITIAL AND lr_batch IS INITIAL.
      lr_erdat = VALUE #( ( sign = 'I' option = 'GE'
                            low  = sy-datum - COND i( WHEN iv_days > 0 THEN iv_days ELSE 30 ) ) ).
    ENDIF.
    IF iv_open_only = abap_true.
      lr_closed = VALUE #( ( sign = 'I' option = 'EQ' low = ' ' ) ).
    ENDIF.

    " GJAHR '0000' is the 2012 migration duplicate set (see ZI_VH_Batch);
    " excluding it makes BATCHNO unique.
    SELECT b~batchno, b~gjahr, b~werks, b~aufnr, b~bchdate, b~lotno,
           b~grey_code, b~grey_item, b~dye_code, b~dye_item,
           b~qty, b~vrkme, b~cheeses, b~assigned, b~closed, b~ernam, b~erdat, b~erzet,
           j~jobno, j~schno, j~dye_arbpl, j~win_arbpl
      FROM zpp_batchn AS b
      LEFT OUTER JOIN zpp_jobn AS j ON j~batchno = b~batchno AND j~delind <> 'X'
      WHERE b~werks   = @iv_werks
        AND b~gjahr  <> '0000'
        AND b~delind <> 'X'
        AND b~aufnr   IN @lr_aufnr
        AND b~batchno IN @lr_batch
        AND b~erdat   IN @lr_erdat
        AND b~closed  IN @lr_closed
      ORDER BY b~erdat DESCENDING, b~erzet DESCENDING, b~batchno DESCENDING
      INTO TABLE @DATA(lt_b)
      UP TO 500 ROWS.

    LOOP AT lt_b INTO DATA(ls_b).
      APPEND INITIAL LINE TO rt_batches ASSIGNING FIELD-SYMBOL(<ls>).
      <ls>-batchno   = ls_b-batchno.
      <ls>-gjahr     = ls_b-gjahr.
      <ls>-werks     = ls_b-werks.
      <ls>-aufnr     = aufnr_out( ls_b-aufnr ).
      <ls>-bchdate   = date_out( ls_b-bchdate ).
      <ls>-lotno     = ls_b-lotno.
      <ls>-grey_code = ls_b-grey_code.
      <ls>-grey_item = ls_b-grey_item.
      <ls>-dye_code  = ls_b-dye_code.
      <ls>-dye_item  = ls_b-dye_item.
      <ls>-qty       = qty_out( ls_b-qty ).
      <ls>-vrkme     = ls_b-vrkme.
      <ls>-cheeses   = qty_out( ls_b-cheeses ).
      <ls>-assigned  = ls_b-assigned.
      <ls>-closed    = ls_b-closed.
      <ls>-jobno     = ls_b-jobno.
      <ls>-schno     = ls_b-schno.
      <ls>-dye_arbpl = ls_b-dye_arbpl.
      <ls>-win_arbpl = ls_b-win_arbpl.
      <ls>-ernam     = ls_b-ernam.
      <ls>-erdat     = date_out( ls_b-erdat ).
    ENDLOOP.

  ENDMETHOD.


  METHOD create_batch.

    DATA: lv_aufnr TYPE aufnr,
          lv_date  TYPE d,
          lv_qty   TYPE zde_btqty,
          lv_chs   TYPE p LENGTH 8 DECIMALS 0,
          lv_msg   TYPE string.

    CLEAR: ev_batchno, ev_error.

    IF is_new-werks IS INITIAL OR is_new-aufnr IS INITIAL.
      ev_error = 'Plant and production order are required'.
      RETURN.
    ENDIF.
    lv_aufnr = |{ is_new-aufnr ALPHA = IN }|.

    lv_date = COND #( WHEN is_new-bchdate IS INITIAL THEN sy-datum ELSE is_new-bchdate ).
    TRY.
        lv_qty = is_new-qty.
        lv_chs = is_new-cheeses.
      CATCH cx_sy_conversion_error.
        ev_error = 'Quantity and cheeses must be numbers'.
        RETURN.
    ENDTRY.

    " Everything else - released order, dyed material on the order, grey
    " code among its components, lot not already open, order quantity
    " ceiling, number range - is refused inside the action with
    " ZBATCH01N's own wording.
    MODIFY ENTITIES OF zi_wip_batch_mgmt
      ENTITY WipBatch
      EXECUTE createBatch
      FROM VALUE #( ( %cid   = 'NEW'
                      %param = VALUE #( plant           = is_new-werks
                                        productionorder = lv_aufnr
                                        batchdate       = lv_date
                                        lotno           = to_upper( is_new-lotno )
                                        greymaterial    = to_upper( is_new-grey_code )
                                        dyedmaterial    = to_upper( is_new-dye_code )
                                        quantity        = lv_qty
                                        batchunit       = COND #( WHEN is_new-vrkme IS INITIAL THEN 'KG' ELSE to_upper( is_new-vrkme ) )
                                        cheeses         = lv_chs ) ) )
      RESULT DATA(lt_res)
      FAILED DATA(ls_failed)
      REPORTED DATA(ls_reported).

    IF ls_failed-wipbatch IS NOT INITIAL.
      ev_error = reported_text( ls_reported-wipbatch ).
      IF ev_error IS INITIAL.
        ev_error = 'The batch could not be created'.
      ENDIF.
      ROLLBACK ENTITIES.
      RETURN.
    ENDIF.

    READ TABLE lt_res INTO DATA(ls_res) INDEX 1.
    lv_msg = ls_res-%param-message.

    " The action answers in words. "Batch 2120000024 created for order
    " ..." is success; anything else is its refusal, which is returned as
    " the error so the number range is not spent twice on a retry loop.
    FIND PCRE 'Batch (\S+) created for order' IN lv_msg SUBMATCHES DATA(lv_new).
    IF sy-subrc <> 0.
      ev_error = lv_msg.
      ROLLBACK ENTITIES.
      RETURN.
    ENDIF.

    COMMIT ENTITIES RESPONSE OF zi_wip_batch_mgmt
      FAILED DATA(ls_cfailed)
      REPORTED DATA(ls_creported).
    IF ls_cfailed-wipbatch IS NOT INITIAL.
      ev_error = reported_text( ls_creported-wipbatch ).
      IF ev_error IS INITIAL.
        ev_error = 'The batch could not be saved'.
      ENDIF.
      RETURN.
    ENDIF.

    ev_batchno = lv_new.

    write_log( iv_charg  = ev_batchno
               iv_action = 'B'
               iv_user   = iv_user
               iv_note   = |Batch from order { aufnr_out( lv_aufnr ) } / { qty_out( lv_qty ) } { is_new-vrkme } / lot { is_new-lotno }| ).
    COMMIT WORK.

  ENDMETHOD.


  METHOD close_batch.

    DATA lv_list   TYPE string.
    DATA lv_msg    TYPE string.
    DATA lv_failed TYPE abap_bool.

    CLEAR: ev_message, ev_error.

    IF iv_batchno IS INITIAL OR iv_gjahr IS INITIAL.
      ev_error = 'Batch and year are required'.
      RETURN.
    ENDIF.
    lv_list = |{ iv_batchno }={ iv_gjahr }|.

    " Two actions, two result types - each call keeps its own variables.
    IF iv_reopen = abap_true.
      IF iv_reason IS INITIAL.
        ev_error = 'A reason is required to reopen a batch'.
        RETURN.
      ENDIF.
      MODIFY ENTITIES OF zi_wip_batch_mgmt
        ENTITY WipBatch
        EXECUTE reopenBatches
        FROM VALUE #( ( %cid = 'R' %param = VALUE #( batchlist = lv_list reason = iv_reason ) ) )
        RESULT DATA(lt_res_r)
        FAILED DATA(ls_failed_r)
        REPORTED DATA(ls_reported_r).
      IF ls_failed_r-wipbatch IS NOT INITIAL.
        lv_failed = abap_true.
        ev_error  = reported_text( ls_reported_r-wipbatch ).
      ELSE.
        READ TABLE lt_res_r INTO DATA(ls_res_r) INDEX 1.
        lv_msg = ls_res_r-%param-message.
      ENDIF.
    ELSE.
      MODIFY ENTITIES OF zi_wip_batch_mgmt
        ENTITY WipBatch
        EXECUTE closeBatches
        FROM VALUE #( ( %cid = 'C' %param = VALUE #( batchlist = lv_list ) ) )
        RESULT DATA(lt_res_c)
        FAILED DATA(ls_failed_c)
        REPORTED DATA(ls_reported_c).
      IF ls_failed_c-wipbatch IS NOT INITIAL.
        lv_failed = abap_true.
        ev_error  = reported_text( ls_reported_c-wipbatch ).
      ELSE.
        READ TABLE lt_res_c INTO DATA(ls_res_c) INDEX 1.
        lv_msg = ls_res_c-%param-message.
      ENDIF.
    ENDIF.

    IF lv_failed = abap_true.
      IF ev_error IS INITIAL.
        ev_error = 'The batch could not be changed'.
      ENDIF.
      ROLLBACK ENTITIES.
      RETURN.
    ENDIF.

    " "2120000024: closed." / "...: reopened." are the two successes; every
    " refusal ("please post all the boxes first", "not authorised ...")
    " comes back as the error.
    IF lv_msg CS ': closed.' OR lv_msg CS ': reopened.'.
      COMMIT ENTITIES RESPONSE OF zi_wip_batch_mgmt
        FAILED DATA(ls_cfailed)
        REPORTED DATA(ls_creported).
      IF ls_cfailed-wipbatch IS NOT INITIAL.
        ev_error = reported_text( ls_creported-wipbatch ).
        IF ev_error IS INITIAL.
          ev_error = 'The batch could not be saved'.
        ENDIF.
        RETURN.
      ENDIF.
      ev_message = lv_msg.
      write_log( iv_charg  = iv_batchno
                 iv_action = COND #( WHEN iv_reopen = abap_true THEN 'O' ELSE 'C' )
                 iv_user   = iv_user
                 iv_note   = COND #( WHEN iv_reopen = abap_true THEN |Reopened: { iv_reason }| ELSE 'Closed' ) ).
      COMMIT WORK.
    ELSE.
      ROLLBACK ENTITIES.
      ev_error = lv_msg.
    ENDIF.

  ENDMETHOD.


  METHOD list_schedules.

    DATA lr_matnr TYPE RANGE OF matnr.
    DATA lr_schno TYPE RANGE OF zpp_schedulen-schno.
    DATA lr_open  TYPE RANGE OF zpp_schedulen-complete.
    DATA ls_d     TYPE zcl_zsol_scan_read_mpc=>ts_schedule.

    IF iv_matnr IS NOT INITIAL.
      lr_matnr = VALUE #( ( sign = 'I' option = 'EQ' low = iv_matnr ) ).
    ENDIF.
    IF iv_schno IS NOT INITIAL.
      lr_schno = VALUE #( ( sign = 'I' option = 'EQ' low = iv_schno ) ).
    ENDIF.
    " A schedule asked for by number is answered whatever its state.
    IF iv_open_only = abap_true AND iv_schno IS INITIAL.
      lr_open = VALUE #( ( sign = 'I' option = 'EQ' low = ' ' ) ).
    ENDIF.

    " Sum of the batches already carded against each schedule, so the
    " operator sees what is left to dye against the promise.
    SELECT s~schno, s~gjahr, s~werks, s~kdno, s~schdt, s~dyedt, s~vbeln, s~posnr,
           s~matnr, s~maktx, s~sch_qty, s~vrkme, s~shdcd, s~remarks, s~complete,
           h~descr
      FROM zpp_schedulen AS s
      LEFT OUTER JOIN zpp_shade AS h ON h~shdcd = s~shdcd
      WHERE s~werks    = @iv_werks
        AND s~delind  <> 'X'
        AND s~matnr    IN @lr_matnr
        AND s~schno    IN @lr_schno
        AND s~complete IN @lr_open
      ORDER BY s~schdt DESCENDING, s~schno DESCENDING
      INTO TABLE @DATA(lt_s)
      UP TO 300 ROWS.

    IF lt_s IS INITIAL.
      RETURN.
    ENDIF.

    TYPES: BEGIN OF ty_done, schno TYPE zpp_schedulen-schno, qty TYPE zpp_batchn-qty, cnt TYPE i, END OF ty_done.
    DATA lt_done TYPE SORTED TABLE OF ty_done WITH UNIQUE KEY schno.
    DATA ls_done TYPE ty_done.
    SELECT j~schno, b~qty
      FROM zpp_jobn AS j
      INNER JOIN zpp_batchn AS b ON b~batchno = j~batchno AND b~gjahr <> '0000' AND b~delind <> 'X'
      FOR ALL ENTRIES IN @lt_s
      WHERE j~schno = @lt_s-schno
        AND j~delind <> 'X'
      INTO TABLE @DATA(lt_jq).
    LOOP AT lt_jq INTO DATA(ls_jq).
      READ TABLE lt_done ASSIGNING FIELD-SYMBOL(<ls_done>) WITH TABLE KEY schno = ls_jq-schno.
      IF sy-subrc <> 0.
        INSERT VALUE #( schno = ls_jq-schno ) INTO TABLE lt_done ASSIGNING <ls_done>.
      ENDIF.
      <ls_done>-qty = <ls_done>-qty + ls_jq-qty.
      <ls_done>-cnt = <ls_done>-cnt + 1.
    ENDLOOP.

    LOOP AT lt_s INTO DATA(ls_s).
      CLEAR ls_done.
      READ TABLE lt_done INTO ls_done WITH TABLE KEY schno = ls_s-schno.
      IF sy-subrc <> 0.
        CLEAR ls_done.
      ENDIF.

      " Open = something left to batch (07.09.2026). A schedule that is
      " already fully or over-batched is not offered in the open list;
      " it still comes back when asked for by number or with all.
      IF iv_open_only = abap_true AND iv_schno IS INITIAL AND ls_done-qty >= ls_s-sch_qty.
        CONTINUE.
      ENDIF.

      APPEND INITIAL LINE TO rt_sched ASSIGNING FIELD-SYMBOL(<ls>).
      <ls>-schno    = ls_s-schno.
      <ls>-gjahr    = ls_s-gjahr.
      <ls>-werks    = ls_s-werks.
      <ls>-kdno     = ls_s-kdno.
      <ls>-schdt    = date_out( ls_s-schdt ).
      <ls>-dyedt    = date_out( ls_s-dyedt ).
      <ls>-vbeln    = ls_s-vbeln.
      <ls>-posnr    = ls_s-posnr.
      <ls>-matnr    = ls_s-matnr.
      <ls>-maktx    = ls_s-maktx.
      <ls>-sch_qty  = qty_out( ls_s-sch_qty ).
      <ls>-vrkme    = ls_s-vrkme.
      <ls>-shdcd    = ls_s-shdcd.
      <ls>-shade    = ls_s-descr.
      <ls>-remarks  = ls_s-remarks.
      <ls>-complete = ls_s-complete.
      <ls>-customer = customer_of( ls_s-vbeln ).
      IF ls_done-cnt > 0.
        <ls>-batched_qty = qty_out( ls_done-qty ).
        <ls>-job_cnt     = ls_done-cnt.
      ELSE.
        <ls>-batched_qty = '0'.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.


  METHOD list_workcenters.

    SELECT h~arbpl, h~werks, t~ktext
      FROM crhd AS h
      LEFT OUTER JOIN crtx AS t ON t~objty = h~objty AND t~objid = h~objid AND t~spras = @sy-langu
      WHERE h~objty = 'A'
        AND h~werks = @iv_werks
      ORDER BY h~arbpl
      INTO TABLE @DATA(lt_wc).

    IF lt_wc IS INITIAL.
      RETURN.
    ENDIF.

    " Which of them the floor actually uses as dyeing and winding machines
    " is read off the job cards, not guessed from the name.
    SELECT dye_arbpl AS arbpl, COUNT(*) AS cnt FROM zpp_jobn
      WHERE werks = @iv_werks AND delind <> 'X' AND dye_arbpl <> @space
      GROUP BY dye_arbpl
      INTO TABLE @DATA(lt_dye).
    SELECT win_arbpl AS arbpl, COUNT(*) AS cnt FROM zpp_jobn
      WHERE werks = @iv_werks AND delind <> 'X' AND win_arbpl <> @space
      GROUP BY win_arbpl
      INTO TABLE @DATA(lt_win).
    SORT: lt_dye BY arbpl, lt_win BY arbpl.

    LOOP AT lt_wc INTO DATA(ls_wc).
      APPEND INITIAL LINE TO rt_wc ASSIGNING FIELD-SYMBOL(<ls>).
      <ls>-werks = ls_wc-werks.
      <ls>-arbpl = ls_wc-arbpl.
      <ls>-ktext = ls_wc-ktext.
      READ TABLE lt_dye INTO DATA(ls_d) WITH KEY arbpl = ls_wc-arbpl BINARY SEARCH.
      DATA(lv_dye) = COND i( WHEN sy-subrc = 0 THEN ls_d-cnt ).
      READ TABLE lt_win INTO DATA(ls_w) WITH KEY arbpl = ls_wc-arbpl BINARY SEARCH.
      DATA(lv_win) = COND i( WHEN sy-subrc = 0 THEN ls_w-cnt ).
      <ls>-used = lv_dye + lv_win.
      <ls>-kind = COND #( WHEN lv_dye > lv_win THEN 'D'
                          WHEN lv_win > 0 THEN 'W'
                          WHEN ls_wc-arbpl CP 'DYG*' THEN 'D'
                          WHEN ls_wc-arbpl CP 'WIN*' THEN 'W' ).
    ENDLOOP.

    SORT rt_wc BY kind DESCENDING used DESCENDING arbpl.
    " DESCENDING on KIND puts W before D; the dyeing machines are wanted
    " first because they are mandatory on the card.
    DATA lt_sorted TYPE tt_wc.
    LOOP AT rt_wc INTO DATA(ls_x) WHERE kind = 'D'.
      APPEND ls_x TO lt_sorted.
    ENDLOOP.
    LOOP AT rt_wc INTO ls_x WHERE kind = 'W'.
      APPEND ls_x TO lt_sorted.
    ENDLOOP.
    LOOP AT rt_wc INTO ls_x WHERE kind <> 'D' AND kind <> 'W'.
      APPEND ls_x TO lt_sorted.
    ENDLOOP.
    rt_wc = lt_sorted.

  ENDMETHOD.


  METHOD list_jobcards.

    DATA lr_jobno TYPE RANGE OF charg_d.
    DATA lr_erdat TYPE RANGE OF erdat.

    IF iv_jobno IS NOT INITIAL.
      lr_jobno = VALUE #( ( sign = 'I' option = 'EQ' low = iv_jobno ) ).
    ELSE.
      lr_erdat = VALUE #( ( sign = 'I' option = 'GE'
                            low  = sy-datum - COND i( WHEN iv_days > 0 THEN iv_days ELSE 30 ) ) ).
    ENDIF.

    " ZI_JobCardReport is the Fiori report's own view: batch, schedule,
    " shade, order and the confirmation dates joined once, soft-deleted
    " cards excluded. One row per card.
    SELECT * FROM zi_jobcardreport
      WHERE Plant         = @iv_werks
        AND JobCard       IN @lr_jobno
        AND CreatedOnDate IN @lr_erdat
      ORDER BY CreatedOnDate DESCENDING, JobCard DESCENDING
      INTO TABLE @DATA(lt_j)
      UP TO 500 ROWS.

    LOOP AT lt_j INTO DATA(ls_j).
      APPEND INITIAL LINE TO rt_jobs ASSIGNING FIELD-SYMBOL(<ls>).
      <ls>-jobno         = ls_j-JobCard.
      <ls>-werks         = ls_j-Plant.
      <ls>-batchno       = ls_j-Batch.
      <ls>-gjahr         = ls_j-FiscalYear.
      <ls>-schno         = ls_j-ScheduleNumber.
      <ls>-aufnr         = aufnr_out( ls_j-ProductionOrder ).
      <ls>-dye_arbpl     = ls_j-DyeingWorkCenter.
      <ls>-dye_arbpl_txt = wc_text( iv_werks = ls_j-Plant iv_arbpl = ls_j-DyeingWorkCenter ).
      <ls>-win_arbpl     = ls_j-WindingWorkCenter.
      <ls>-win_arbpl_txt = wc_text( iv_werks = ls_j-Plant iv_arbpl = ls_j-WindingWorkCenter ).
      <ls>-bchdate       = date_out( ls_j-BatchDate ).
      <ls>-schdt         = date_out( ls_j-ScheduleDate ).
      <ls>-dyedt         = date_out( ls_j-PlannedDyeingDate ).
      <ls>-dyeing_date   = date_out( ls_j-DyeingDate ).
      <ls>-winding_date  = date_out( ls_j-WindingDate ).
      <ls>-dye_conf      = ls_j-DyeingConfirmations.
      <ls>-win_conf      = ls_j-WindingConfirmations.
      <ls>-lotno         = ls_j-LotNo.
      <ls>-grey_code     = ls_j-GreyMaterial.
      <ls>-grey_item     = ls_j-GreyMaterialName.
      <ls>-dye_code      = ls_j-DyedMaterial.
      <ls>-dye_item      = ls_j-DyedMaterialName.
      <ls>-shdcd         = ls_j-ShadeCode.
      <ls>-shade         = ls_j-ShadeName.
      <ls>-kdno          = ls_j-CustomerReference.
      <ls>-vbeln         = ls_j-SalesOrder.
      <ls>-posnr         = ls_j-SalesOrderItem.
      <ls>-customer      = customer_of( ls_j-SalesOrder ).
      <ls>-qty           = qty_out( ls_j-Quantity ).
      <ls>-vrkme         = ls_j-BatchUnit.
      <ls>-cheeses       = qty_out( ls_j-Cheeses ).
      <ls>-sch_qty       = qty_out( ls_j-ScheduleQuantity ).
      <ls>-sch_vrkme     = ls_j-ScheduleUnit.
      <ls>-assigned      = ls_j-Assigned.
      <ls>-closed        = ls_j-Closed.
      <ls>-complete      = ls_j-ScheduleComplete.
      <ls>-ernam         = ls_j-CreatedBy.
      <ls>-erdat         = date_out( ls_j-CreatedOnDate ).
    ENDLOOP.

  ENDMETHOD.


  METHOD get_recipe.

    " The card's four keys - plant, grey, dyed, shade - select the recipe
    " exactly (ZPP_RECEIPE is keyed on them plus the line).
    SELECT SINGLE Plant, GreyMaterial, DyedMaterial, ShadeCode
      FROM zi_jobcardreport
      WHERE JobCard = @iv_jobno
      INTO @DATA(ls_key).
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.

    SELECT * FROM zi_jobcardrecipe
      WHERE Plant        = @ls_key-Plant
        AND GreyMaterial = @ls_key-GreyMaterial
        AND DyedMaterial = @ls_key-DyedMaterial
        AND ShadeCode    = @ls_key-ShadeCode
      ORDER BY RecipeItem
      INTO TABLE @DATA(lt_r).

    LOOP AT lt_r INTO DATA(ls_r).
      APPEND INITIAL LINE TO rt_recipe ASSIGNING FIELD-SYMBOL(<ls>).
      <ls>-jobno     = iv_jobno.
      <ls>-werks     = ls_r-Plant.
      <ls>-grey_code = ls_r-GreyMaterial.
      <ls>-dye_code  = ls_r-DyedMaterial.
      <ls>-shdcd     = ls_r-ShadeCode.
      <ls>-posnr     = ls_r-RecipeItem.
      <ls>-component = ls_r-Component.
      <ls>-comp_desc = ls_r-ComponentName.
      <ls>-comp_type = ls_r-ComponentType.
      <ls>-ratio     = qty_out( ls_r-Ratio ).
      <ls>-vrkme     = ls_r-RatioUnit.
      <ls>-remarks   = ls_r-Remarks.
    ENDLOOP.

  ENDMETHOD.


  METHOD create_jobcard.

    DATA lv_win TYPE arbpl.

    CLEAR: ev_jobno, ev_error.

    IF iv_batchno IS INITIAL.
      ev_error = 'Enter Batch No.'.       RETURN.
    ENDIF.
    IF iv_schno IS INITIAL.
      ev_error = 'Enter Schedule No.'.    RETURN.
    ENDIF.
    IF iv_dye_arbpl IS INITIAL.
      ev_error = 'Enter Dying Machine'.   RETURN.
    ENDIF.

    " ---- the batch: live, and not already carded (ZJOB01N: ASSIGNED <> X)
    SELECT SINGLE batchno, gjahr, werks, aufnr, dye_code, assigned, closed
      FROM zpp_batchn
      WHERE batchno = @iv_batchno AND gjahr <> '0000' AND delind <> 'X'
      INTO @DATA(ls_bat).
    IF sy-subrc <> 0.
      ev_error = |Invalid Batch Number { iv_batchno }|.
      RETURN.
    ENDIF.
    SELECT SINGLE jobno FROM zpp_jobn
      WHERE batchno = @iv_batchno AND delind <> 'X'
      INTO @DATA(lv_have).
    IF sy-subrc = 0.
      ev_error = |Batch { iv_batchno } already has job card { lv_have }|.
      RETURN.
    ENDIF.
    IF ls_bat-assigned = 'X'.
      ev_error = |Batch { iv_batchno } is already assigned|.
      RETURN.
    ENDIF.
    IF ls_bat-closed = 'X'.
      ev_error = |Batch { iv_batchno } is closed|.
      RETURN.
    ENDIF.

    " ---- the schedule: same plant, same dyed material (ZJOB01N: MATNR = DYE_CODE)
    SELECT SINGLE schno, werks, matnr, vbeln, posnr, complete
      FROM zpp_schedulen
      WHERE schno = @iv_schno AND delind <> 'X'
      INTO @DATA(ls_sch).
    IF sy-subrc <> 0.
      ev_error = |Invalid Schedule No. { iv_schno }|.
      RETURN.
    ENDIF.
    IF ls_sch-matnr <> ls_bat-dye_code.
      ev_error = |Schedule { iv_schno } is for { ls_sch-matnr }, the batch dyes { ls_bat-dye_code }|.
      RETURN.
    ENDIF.
    IF ls_sch-werks <> ls_bat-werks.
      ev_error = |Schedule { iv_schno } belongs to plant { ls_sch-werks }, the batch to { ls_bat-werks }|.
      RETURN.
    ENDIF.

    " ---- the machines, in the batch's plant
    IF wc_text( iv_werks = ls_bat-werks iv_arbpl = iv_dye_arbpl ) IS INITIAL.
      SELECT SINGLE arbpl FROM crhd WHERE objty = 'A' AND werks = @ls_bat-werks AND arbpl = @iv_dye_arbpl
        INTO @DATA(lv_chk).
      IF sy-subrc <> 0.
        ev_error = |Invalid Work Center No. { iv_dye_arbpl }|.
        RETURN.
      ENDIF.
    ENDIF.
    IF iv_win_arbpl IS NOT INITIAL.
      SELECT SINGLE arbpl FROM crhd WHERE objty = 'A' AND werks = @ls_bat-werks AND arbpl = @iv_win_arbpl
        INTO @lv_win.
      IF sy-subrc <> 0.
        ev_error = |Invalid Work Center No. { iv_win_arbpl }|.
        RETURN.
      ENDIF.
    ENDIF.

    " ---- write it through ZI_Job: the managed save inserts ZPP_JOBN and
    " the additional save stamps ZPP_BATCHN-ASSIGNED, as ZJOB01N does.
    MODIFY ENTITIES OF zi_job
      ENTITY Job
      CREATE FIELDS ( JobNumber BatchNumber ScheduleNumber Plant DyeingWorkCenter WindingWorkCenter )
      WITH VALUE #( ( %cid              = 'JC'
                      JobNumber         = iv_batchno
                      BatchNumber       = iv_batchno
                      ScheduleNumber    = iv_schno
                      Plant             = ls_bat-werks
                      DyeingWorkCenter  = iv_dye_arbpl
                      WindingWorkCenter = lv_win ) )
      MAPPED DATA(ls_mapped)
      FAILED DATA(ls_failed)
      REPORTED DATA(ls_reported).

    IF ls_failed-job IS NOT INITIAL.
      ev_error = reported_text( ls_reported-job ).
      IF ev_error IS INITIAL.
        ev_error = 'The job card could not be created'.
      ENDIF.
      ROLLBACK ENTITIES.
      RETURN.
    ENDIF.

    COMMIT ENTITIES RESPONSE OF zi_job
      FAILED DATA(ls_cfailed)
      REPORTED DATA(ls_creported).
    IF ls_cfailed-job IS NOT INITIAL.
      ev_error = reported_text( ls_creported-job ).
      IF ev_error IS INITIAL.
        ev_error = 'The job card could not be saved'.
      ENDIF.
      RETURN.
    ENDIF.

    ev_jobno = iv_batchno.

    write_log( iv_vbeln  = ls_sch-vbeln
               iv_posnr  = ls_sch-posnr
               iv_charg  = iv_batchno
               iv_action = 'J'
               iv_user   = iv_user
               iv_note   = |Job card / schedule { iv_schno } / { iv_dye_arbpl } { lv_win }| ).
    COMMIT WORK.

  ENDMETHOD.

ENDCLASS.
