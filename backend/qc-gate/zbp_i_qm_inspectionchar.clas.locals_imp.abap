*"* Local types for behaviour pool ZBP_I_QM_INSPECTIONCHAR
*"* -------------------------------------------------------------------------
*"* Paste into the "Class-relevant Local Types" tab. The Global Class tab stays
*"* as it is (empty skeleton).
*"*
*"* Serves ZREC_INSP_MASS - "Record Inspection Results (Mass)". The UI PATCHes
*"* ResultValue / Valuation on ZC_QM_INSPECTIONCHAR rows and submits one $batch;
*"* update( ) validates and buffers, save( ) posts through the QM BAPI.
*"*
*"* 2026-09-05 (QC audit) - three faults in the previous version, all in the
*"* posting path, all silent:
*"*
*"*   1. BAPI_INSPCHAR_SETRESULT ran DESTINATION 'NONE' with NO commit in that
*"*      session. The BAPI only buffers; the separate session was never told to
*"*      commit, so not one result ever reached QAMR. The UI meanwhile showed
*"*      "n result(s) posted".
*"*   2. RETURN from the BAPI was read into a variable and never looked at. A
*"*      rejected value (closed characteristic, wrong lot status, no
*"*      authorization) produced no message anywhere.
*"*   3. update( ) CLEARed the buffer on entry. A $batch with several rows
*"*      reaches the handler as several update calls inside one transaction,
*"*      so every call wiped the rows of the calls before it and only the last
*"*      row of a mass entry could ever have been posted.
*"*
*"* The BAPI stays in its own session (DESTINATION 'NONE') and is now followed
*"* by BAPI_TRANSACTION_COMMIT in that same session - which is what actually
*"* writes - or BAPI_TRANSACTION_ROLLBACK when the BAPI rejects the row. Every
*"* RETURN message is passed back through reported, so the app can tell the
*"* operator which row did not post. The buffer is cleared after save and in
*"* cleanup, never on entry.
*"* -------------------------------------------------------------------------

CLASS lsc_InspectionChar DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PUBLIC SECTION.
    " Valid rows the UI submitted, handed from the interaction phase to save.
    " Keyed so a row PATCHed twice in one $batch is posted once, with the
    " last values.
    CLASS-DATA gt_buffer TYPE TABLE FOR UPDATE ZI_QM_InspectionChar.

    CLASS-METHODS reset.
  PROTECTED SECTION.
    METHODS save             REDEFINITION.
    METHODS cleanup          REDEFINITION.
    METHODS cleanup_finalize REDEFINITION.
ENDCLASS.

CLASS lhc_InspectionChar DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS update FOR MODIFY IMPORTING entities FOR UPDATE InspectionChar.
ENDCLASS.

CLASS lhc_InspectionChar IMPLEMENTATION.
  METHOD update.
    " Interaction phase: per-row validation (reads only) + buffering.
    " The QM BAPI writes the database, which RAP forbids here, so the post
    " happens in save(); this method only validates the entered values and
    " hands the good rows over. failed/reported are available in this phase,
    " so a bad row is rejected against its own key and nothing it submitted
    " posts.
    DATA lv_inspoper TYPE bapi2045d4-inspoper.

    LOOP AT entities INTO DATA(ls_char).

      " Only consider characteristics the user actually filled in.
      IF ls_char-ResultValue IS INITIAL AND ls_char-Valuation IS INITIAL.
        CONTINUE.
      ENDIF.

      " 1. Valuation, if entered, must be Accepted (A) or Rejected (R).
      IF ls_char-Valuation IS NOT INITIAL
         AND ls_char-Valuation <> 'A' AND ls_char-Valuation <> 'R'.
        APPEND VALUE #( %tky = ls_char-%tky ) TO failed-inspectionchar.
        APPEND VALUE #( %tky = ls_char-%tky
                        %msg = new_message_with_text(
                                 severity = if_abap_behv_message=>severity-error
                                 text     = |Invalid valuation '{ ls_char-Valuation }'. Use A (accept) or R (reject).| ) )
               TO reported-inspectionchar.
        CONTINUE.
      ENDIF.

      " 2. The lot must still take results: no usage decision yet.
      SELECT SINGLE stat35 FROM qals
        WHERE prueflos = @ls_char-InspectionLot
        INTO @DATA(lv_ud_made).
      IF sy-subrc <> 0 OR lv_ud_made = 'X'.
        APPEND VALUE #( %tky = ls_char-%tky ) TO failed-inspectionchar.
        APPEND VALUE #( %tky = ls_char-%tky
                        %msg = new_message_with_text(
                                 severity = if_abap_behv_message=>severity-error
                                 text     = |Inspection lot { ls_char-InspectionLot } already has a usage decision - no further results.| ) )
               TO reported-inspectionchar.
        CONTINUE.
      ENDIF.

      " 3. The operation reference (VORGLFNR) must resolve to an operation number.
      SELECT SINGLE inspectionoperation FROM i_inspectionoperation
        WHERE inspectionlot               = @ls_char-InspectionLot
          AND inspplanoperationinternalid = @ls_char-InspectionOperation
        INTO @lv_inspoper.
      IF sy-subrc <> 0.
        APPEND VALUE #( %tky = ls_char-%tky ) TO failed-inspectionchar.
        APPEND VALUE #( %tky = ls_char-%tky
                        %msg = new_message_with_text(
                                 severity = if_abap_behv_message=>severity-error
                                 text     = |No operation found for inspection lot { ls_char-InspectionLot }.| ) )
               TO reported-inspectionchar.
        CONTINUE.
      ENDIF.

      " Valid -> hand to the save phase. Same key already buffered by an
      " earlier call in this transaction: replace, do not duplicate.
      READ TABLE lsc_InspectionChar=>gt_buffer ASSIGNING FIELD-SYMBOL(<ls_buf>)
           WITH KEY InspectionLot            = ls_char-InspectionLot
                    InspectionOperation      = ls_char-InspectionOperation
                    InspectionCharacteristic = ls_char-InspectionCharacteristic.
      IF sy-subrc = 0.
        <ls_buf> = ls_char.
      ELSE.
        APPEND ls_char TO lsc_InspectionChar=>gt_buffer.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.

CLASS lsc_InspectionChar IMPLEMENTATION.

  METHOD reset.
    CLEAR gt_buffer.
  ENDMETHOD.

  METHOD save.
    DATA ls_return   TYPE bapireturn1.
    DATA ls_cret     TYPE bapiret2.
    DATA lv_rfcmsg   TYPE c LENGTH 200.
    DATA lv_insplot  TYPE bapi2045d4-insplot.
    DATA lv_inspoper TYPE bapi2045d4-inspoper.
    DATA lv_inspchar TYPE bapi2045d4-inspchar.
    DATA lv_dec      TYPE decfloat34.
    DATA lv_ok       TYPE i.
    DATA lv_bad      TYPE i.

    LOOP AT gt_buffer INTO DATA(ls_char).
      " Operation number (VORNR) for the BAPI; already validated in update().
      CLEAR lv_inspoper.
      SELECT SINGLE inspectionoperation FROM i_inspectionoperation
        WHERE inspectionlot               = @ls_char-InspectionLot
          AND inspplanoperationinternalid = @ls_char-InspectionOperation
        INTO @lv_inspoper.

      lv_insplot  = ls_char-InspectionLot.
      lv_inspchar = ls_char-InspectionCharacteristic.

      " BAPI2045D2-MEAN_VALUE is CHAR 22. DECFLOAT34 with NUMBER = RAW gives a
      " plain decimal string with a '.' separator, which is what QM parses.
      DATA(ls_result) = VALUE bapi2045d2(
        insplot    = lv_insplot
        inspoper   = lv_inspoper
        inspchar   = lv_inspchar
        evaluation = ls_char-Valuation
        closed     = 'X' ).
      IF ls_char-ResultValue IS NOT INITIAL.
        lv_dec = ls_char-ResultValue.
        ls_result-mean_value = |{ lv_dec NUMBER = RAW }|.
      ENDIF.

      " The BAPI runs in its own session (DESTINATION 'NONE'), so its LUW is
      " independent of the RAP LUW this method sits in - and so it has to be
      " committed THERE. Without the commit below nothing is ever written.
      CLEAR: ls_return, lv_rfcmsg.
      CALL FUNCTION 'BAPI_INSPCHAR_SETRESULT' DESTINATION 'NONE'
        EXPORTING
          insplot     = lv_insplot
          inspoper    = lv_inspoper
          inspchar    = lv_inspchar
          char_result = ls_result
        IMPORTING
          return      = ls_return
        EXCEPTIONS
          system_failure        = 1 MESSAGE lv_rfcmsg
          communication_failure = 2 MESSAGE lv_rfcmsg
          OTHERS                = 3.

      IF sy-subrc <> 0.
        lv_bad = lv_bad + 1.
        APPEND VALUE #( %tky = ls_char-%tky
                        %msg = new_message_with_text(
                                 severity = if_abap_behv_message=>severity-error
                                 text     = |Lot { lv_insplot } char. { lv_inspchar }: { lv_rfcmsg }| ) )
               TO reported-inspectionchar.
        CONTINUE.
      ENDIF.

      IF ls_return-type CA 'EA'.
        lv_bad = lv_bad + 1.
        CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK' DESTINATION 'NONE'
          EXCEPTIONS OTHERS = 1.
        APPEND VALUE #( %tky = ls_char-%tky
                        %msg = new_message( id       = ls_return-id
                                            number   = ls_return-number
                                            severity = if_abap_behv_message=>severity-error
                                            v1       = ls_return-message_v1
                                            v2       = ls_return-message_v2
                                            v3       = ls_return-message_v3
                                            v4       = ls_return-message_v4 ) )
               TO reported-inspectionchar.
        CONTINUE.
      ENDIF.

      CLEAR ls_cret.
      CALL FUNCTION 'BAPI_TRANSACTION_COMMIT' DESTINATION 'NONE'
        EXPORTING
          wait   = 'X'
        IMPORTING
          return = ls_cret
        EXCEPTIONS
          system_failure        = 1 MESSAGE lv_rfcmsg
          communication_failure = 2 MESSAGE lv_rfcmsg
          OTHERS                = 3.

      IF sy-subrc <> 0 OR ls_cret-type CA 'EA'.
        lv_bad = lv_bad + 1.
        APPEND VALUE #( %tky = ls_char-%tky
                        %msg = new_message_with_text(
                                 severity = if_abap_behv_message=>severity-error
                                 text     = |Lot { lv_insplot } char. { lv_inspchar }: commit failed - { COND string( WHEN sy-subrc <> 0 THEN lv_rfcmsg ELSE ls_cret-message ) }| ) )
               TO reported-inspectionchar.
        CONTINUE.
      ENDIF.

      lv_ok = lv_ok + 1.
    ENDLOOP.

    IF lv_ok > 0 OR lv_bad > 0.
      APPEND VALUE #( %msg = new_message_with_text(
                               severity = COND #( WHEN lv_bad > 0
                                                  THEN if_abap_behv_message=>severity-warning
                                                  ELSE if_abap_behv_message=>severity-success )
                               text     = |{ lv_ok } result(s) posted, { lv_bad } rejected| ) )
             TO reported-inspectionchar.
    ENDIF.

    reset( ).
  ENDMETHOD.

  METHOD cleanup.
    reset( ).
  ENDMETHOD.

  METHOD cleanup_finalize.
    reset( ).
  ENDMETHOD.

ENDCLASS.
