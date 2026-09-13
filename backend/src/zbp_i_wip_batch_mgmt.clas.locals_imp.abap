CLASS lhc_zi_wip_batch_mgmt DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS closebatches FOR MODIFY
      IMPORTING keys FOR ACTION WipBatch~closeBatches RESULT result.
    METHODS reopenbatches FOR MODIFY
      IMPORTING keys FOR ACTION WipBatch~reopenBatches RESULT result.

    " Shared implementation. iv_close = abap_true -> set CLOSED = 'X',
    " abap_false -> clear it. Returns the per-row message text.
    METHODS set_closed
      IMPORTING iv_list       TYPE string
                iv_reason     TYPE string OPTIONAL
                iv_close      TYPE abap_bool
      RETURNING VALUE(rv_msg) TYPE string.

    " The seven conditions ZSOL_WIP_BATCH_CLOSE refuses to close on. Returns an
    " empty string when the batch is ready, otherwise the reason it is not.
    "
    " Ported field for field from form usr_command, WHEN '&CLOSE' in
    " ZSOL_WIP_BATCH_CLOSE, and from form process_data where each figure is
    " built:
    "
    "   post / npost   ZPP_PACK-NETWT, split on GRPOST, matched on
    "                  MERGNO = batch and MATNR = the dyed code
    "   issue_qty      MSEG-MENGE where AUFNR = the order, WEMPF = the batch
    "   oil_qty        and MJAHR = the year; MATNR = grey code is the yarn,
    "                  anything else is the oil. SHKZG = 'H' flips the sign.
    "   erfmg          AFFW-ERFMG (COGI) on WEMPF = the batch, split the same
    "   oil_erfmg      way on the grey code.
    "   oil_btqty      batch quantity * RESB-ESMNG for the non-grey component
    "                  on the order.
    "
    " One deliberate difference: the report hard-codes WERKS = '2002' in the
    " MSEG reads. This uses the batch's own plant, so the guard keeps working
    " when a second plant starts dyeing.
    METHODS why_not_ready
      IMPORTING is_batch      TYPE zpp_batchn
      RETURNING VALUE(rv_why) TYPE string.
ENDCLASS.

CLASS lhc_zi_wip_batch_mgmt IMPLEMENTATION.

  METHOD why_not_ready.

    DATA: lv_post      TYPE zpp_pack-netwt,
          lv_npost     TYPE zpp_pack-netwt,
          lv_issue     TYPE mseg-menge,
          lv_oil_qty   TYPE mseg-menge,
          lv_cogi      TYPE affw-erfmg,
          lv_oil_cogi  TYPE affw-erfmg,
          lv_oil_btqty TYPE zpp_batchn-qty.

    " ---- boxes: everything packed for this batch has to be goods-receipted
    SELECT SUM( netwt ) FROM zpp_pack
      WHERE mergno = @is_batch-batchno
        AND matnr  = @is_batch-dye_code
        AND grpost = 'X'
      INTO @lv_post.

    SELECT SUM( netwt ) FROM zpp_pack
      WHERE mergno = @is_batch-batchno
        AND matnr  = @is_batch-dye_code
        AND grpost <> 'X'
      INTO @lv_npost.

    " ---- consumption: yarn and oil, signed, from the goods issues
    SELECT matnr, shkzg, menge FROM mseg
      WHERE aufnr = @is_batch-aufnr
        AND wempf = @is_batch-batchno
        AND mjahr = @is_batch-gjahr
        AND werks = @is_batch-werks
      INTO TABLE @DATA(lt_mseg).

    LOOP AT lt_mseg INTO DATA(ls_mseg).
      DATA(lv_signed) = ls_mseg-menge.
      IF ls_mseg-shkzg = 'H'.
        lv_signed = lv_signed * -1.
      ENDIF.
      IF ls_mseg-matnr = is_batch-grey_code.
        lv_issue = lv_issue + lv_signed.
      ELSE.
        lv_oil_qty = lv_oil_qty + lv_signed.
      ENDIF.
    ENDLOOP.

    " ---- COGI: postings that failed and are still sitting in AFFW
    SELECT matnr, erfmg FROM affw
      WHERE wempf = @is_batch-batchno
      INTO TABLE @DATA(lt_affw).

    LOOP AT lt_affw INTO DATA(ls_affw).
      IF ls_affw-matnr = is_batch-grey_code.
        lv_cogi = lv_cogi + ls_affw-erfmg.
      ELSE.
        lv_oil_cogi = lv_oil_cogi + ls_affw-erfmg.
      ENDIF.
    ENDLOOP.

    " ---- how much oil the BOM says this batch should have taken
    SELECT matnr, esmng FROM resb
      WHERE werks = @is_batch-werks
        AND aufnr = @is_batch-aufnr
      INTO TABLE @DATA(lt_resb).

    LOOP AT lt_resb INTO DATA(ls_resb).
      IF ls_resb-matnr <> is_batch-grey_code.
        lv_oil_btqty = is_batch-qty * ls_resb-esmng.
      ENDIF.
    ENDLOOP.

    " ---- the seven refusals, in the report's own order and wording
    IF lv_npost > lv_post.
      rv_why = |please post all the boxes first|.
    ELSEIF lv_cogi <> 0.
      rv_why = |please clear the COGI first|.
    ELSEIF lv_issue * -1 > is_batch-qty.
      rv_why = |please adjust the consumption|.
    ELSEIF lv_issue = 0.
      rv_why = |please post all the boxes first|.
    ELSEIF lv_oil_cogi <> 0.
      rv_why = |please clear the OIL COGI first|.
    ELSEIF lv_oil_qty * -1 > lv_oil_btqty.
      rv_why = |please adjust the OIL consumption|.
    ELSEIF lv_oil_qty = 0.
      rv_why = |please post all the boxes first|.
    ENDIF.

  ENDMETHOD.


  METHOD set_closed.
    DATA: lv_batch TYPE zpp_batchn-batchno,
          lv_year  TYPE zpp_batchn-gjahr.

    SPLIT iv_list AT ';' INTO TABLE DATA(lt_pairs).

    LOOP AT lt_pairs INTO DATA(lv_pair).
      CONDENSE lv_pair.
      IF lv_pair IS INITIAL.
        CONTINUE.
      ENDIF.
      SPLIT lv_pair AT '=' INTO DATA(lv_b) DATA(lv_y).
      CONDENSE: lv_b, lv_y.
      lv_batch = lv_b.
      lv_year  = lv_y.

      SELECT SINGLE * FROM zpp_batchn
        WHERE batchno = @lv_batch AND gjahr = @lv_year
        INTO @DATA(ls_bat).
      IF sy-subrc <> 0.
        rv_msg = |{ rv_msg }{ lv_b }: batch not found. |.
        CONTINUE.
      ENDIF.

      IF iv_close = abap_true AND ls_bat-closed = 'X'.
        rv_msg = |{ rv_msg }{ lv_b }: already closed. |.
        CONTINUE.
      ENDIF.
      IF iv_close = abap_false AND ls_bat-closed <> 'X'.
        rv_msg = |{ rv_msg }{ lv_b }: already open. |.
        CONTINUE.
      ENDIF.

      IF iv_close = abap_true.
        " The app used to close on the flag alone. ZBATCH_CLS never did, and a
        " batch closed over unposted boxes or open COGI cannot be corrected
        " afterwards without reopening it.
        DATA(lv_why) = why_not_ready( ls_bat ).
        IF lv_why IS NOT INITIAL.
          rv_msg = |{ rv_msg }{ lv_b }: { lv_why }. |.
          CONTINUE.
        ENDIF.

        UPDATE zpp_batchn
          SET closed      = 'X',
              closed_by   = @sy-uname,
              closed_on   = @sy-datum,
              closed_time = @sy-uzeit
          WHERE batchno = @lv_batch AND gjahr = @lv_year.
      ELSE.
        " Reopen clears the closed flag. The reopen audit columns (REOPEN /
        " REPDAT / REPUN / REPTM) are NOT on ZPP_BATCHN in this system, so
        " who/when a batch was reopened is not stamped here - a reopened batch
        " is indistinguishable from one that was never closed. That audit trail
        " is deferred: MD will add the columns to ZPP_BATCHN and restore the
        " stamp separately. Until then this UPDATE must touch only CLOSED, or
        " the behaviour pool will not compile against the active table.
        UPDATE zpp_batchn
          SET closed = ' '
          WHERE batchno = @lv_batch AND gjahr = @lv_year.
      ENDIF.

      IF sy-subrc = 0.
        IF iv_close = abap_true.
          rv_msg = |{ rv_msg }{ lv_b }: closed. |.
        ELSE.
          rv_msg = |{ rv_msg }{ lv_b }: reopened. |.
        ENDIF.
      ELSE.
        rv_msg = |{ rv_msg }{ lv_b }: update failed. |.
      ENDIF.
    ENDLOOP.

*   No commit here. A behaviour pool may not issue one - the syntax check
*   rejects it outright - and it does not need to: these UPDATEs run inside
*   the RAP LUW and the OData V4 runtime commits it when the action request
*   ends.
    IF rv_msg IS INITIAL.
      rv_msg = |No batch supplied.|.
    ENDIF.
  ENDMETHOD.

  METHOD closebatches.
    LOOP AT keys INTO DATA(ls_key).
      DATA(lv_msg) = set_closed(
        iv_list  = CONV string( ls_key-%param-batchlist )
        iv_close = abap_true ).
      INSERT VALUE #( %cid = ls_key-%cid %param-message = lv_msg ) INTO TABLE result.
    ENDLOOP.
  ENDMETHOD.

  METHOD reopenbatches.
    LOOP AT keys INTO DATA(ls_key).
      " Reopening is the destructive direction - it lets a confirmation be
      " cancelled or deducted afterwards, so a reason is mandatory.
      IF ls_key-%param-reason IS INITIAL.
        INSERT VALUE #( %cid = ls_key-%cid
                        %param-message = |A reason is required to reopen a batch.| )
               INTO TABLE result.
        CONTINUE.
      ENDIF.
      " NOTE: the reason is echoed back and not stored. ZPP_BATCHN has no column
      " for it - and with the reopen audit columns removed, nothing records who,
      " when or why. Storing it needs a REASON column on ZPP_BATCHN or an SLG1 log.
      DATA(lv_msg) = set_closed(
        iv_list   = CONV string( ls_key-%param-batchlist )
        iv_reason = CONV string( ls_key-%param-reason )
        iv_close  = abap_false ).
      INSERT VALUE #( %cid = ls_key-%cid
                      %param-message = |{ lv_msg }Reason: { ls_key-%param-reason }| )
             INTO TABLE result.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.

CLASS lsc_zi_wip_batch_mgmt DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PROTECTED SECTION.
    METHODS save REDEFINITION.
ENDCLASS.

CLASS lsc_zi_wip_batch_mgmt IMPLEMENTATION.
  METHOD save.
  ENDMETHOD.
ENDCLASS.
