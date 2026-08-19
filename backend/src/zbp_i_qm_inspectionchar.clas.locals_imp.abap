CLASS lsc_InspectionChar DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PUBLIC SECTION.
    " Valid rows the UI submitted, handed from the interaction phase to save.
    CLASS-DATA gt_buffer TYPE TABLE FOR UPDATE ZI_QM_InspectionChar.
  PROTECTED SECTION.
    METHODS save REDEFINITION.
ENDCLASS.

CLASS lhc_InspectionChar DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS update FOR MODIFY IMPORTING entities FOR UPDATE InspectionChar.
ENDCLASS.

CLASS lhc_InspectionChar IMPLEMENTATION.
  METHOD update.
    " Interaction phase: per-row validation (reads only) + buffering.
    " The QM API self-commits, so the actual post happens in save(); here we only
    " validate the entered values and hand the good rows over. failed/reported are
    " available in this phase, so bad rows are rejected against their own key and
    " nothing they submitted posts.
    DATA lv_inspoper TYPE bapi2045d4-inspoper.

    " Fresh buffer per submit (guards against a previously aborted transaction).
    CLEAR lsc_InspectionChar=>gt_buffer.

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

      " 2. The operation reference (VORGLFNR) must resolve to an operation number.
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

      " Valid -> hand to the save phase.
      APPEND ls_char TO lsc_InspectionChar=>gt_buffer.
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.

CLASS lsc_InspectionChar IMPLEMENTATION.
  METHOD save.
    DATA ls_return   TYPE bapireturn1.
    DATA lv_rfcmsg   TYPE c LENGTH 200.
    DATA lv_insplot  TYPE bapi2045d4-insplot.
    DATA lv_inspoper TYPE bapi2045d4-inspoper.
    DATA lv_inspchar TYPE bapi2045d4-inspchar.

    LOOP AT gt_buffer INTO DATA(ls_char).
      " Operation number (VORNR) for the BAPI; already validated in update().
      SELECT SINGLE inspectionoperation FROM i_inspectionoperation
        WHERE inspectionlot               = @ls_char-InspectionLot
          AND inspplanoperationinternalid = @ls_char-InspectionOperation
        INTO @lv_inspoper.

      lv_insplot  = ls_char-InspectionLot.
      lv_inspchar = ls_char-InspectionCharacteristic.

      DATA(ls_result) = VALUE bapi2045d2(
        insplot    = lv_insplot
        inspoper   = lv_inspoper
        inspchar   = lv_inspchar
        mean_value = ls_char-ResultValue
        evaluation = ls_char-Valuation
        closed     = 'X' ).

      CLEAR ls_return.
      " The QM results engine (SAPLQEEM) self-commits, which RAP forbids in its
      " LUW - run the BAPI in a separate LUW via aRFC (DESTINATION 'NONE').
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
    ENDLOOP.

    CLEAR gt_buffer.
  ENDMETHOD.
ENDCLASS.
