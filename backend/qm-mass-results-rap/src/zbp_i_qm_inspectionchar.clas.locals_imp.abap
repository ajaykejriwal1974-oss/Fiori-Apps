**********************************************************************
* Unmanaged behavior for ZI_QM_INSPECTIONCHAR
*
* UI edits ResultValue / Valuation per characteristic (UPDATE) and submits.
* Each filled-in characteristic is recorded via the standard QM API
* BAPI_INSPCHAR_SETRESULT (CLOSED = 'X' also closes it - there is no
* BAPI_INSPCHAR_CLOSE on this release). The QM BAPI posts on the update
* task, so nothing persists until the saver COMMITs.
*
* Per-row validation: any characteristic the BAPI rejects is reported
* against its own key (failed + reported), which aborts the whole submit
* before COMMIT - the user sees exactly which rows failed, and nothing posts.
*
* VERIFY on a live lot before go-live: QM valuation/close behaviour.
**********************************************************************
CLASS lsc_InspectionChar DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PUBLIC SECTION.
    CLASS-DATA gv_posted TYPE abap_bool.
    CLASS-DATA gv_error  TYPE abap_bool.
  PROTECTED SECTION.
    METHODS save REDEFINITION.
ENDCLASS.

CLASS lhc_InspectionChar DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS update FOR MODIFY IMPORTING entities FOR UPDATE InspectionChar.
ENDCLASS.

CLASS lhc_InspectionChar IMPLEMENTATION.
  METHOD update.
    DATA ls_return TYPE bapireturn1.

    CLEAR: lsc_InspectionChar=>gv_posted, lsc_InspectionChar=>gv_error.

    LOOP AT entities INTO DATA(ls_char).
      " Only post characteristics the user actually filled in.
      IF ls_char-ResultValue IS INITIAL AND ls_char-Valuation IS INITIAL.
        CONTINUE.
      ENDIF.

      DATA(ls_result) = VALUE bapi2045d2(
        insplot    = ls_char-InspectionLot
        inspoper   = ls_char-InspectionOperation
        inspchar   = ls_char-InspectionCharacteristic
        mean_value = ls_char-ResultValue
        evaluation = ls_char-Valuation
        closed     = 'X' ).

      CLEAR ls_return.
      CALL FUNCTION 'BAPI_INSPCHAR_SETRESULT'
        EXPORTING
          insplot     = ls_char-InspectionLot
          inspoper    = ls_char-InspectionOperation
          inspchar    = ls_char-InspectionCharacteristic
          char_result = ls_result
        IMPORTING
          return      = ls_return.

      IF ls_return-type CA 'EA'.
        " Surface the QM message against this exact characteristic.
        APPEND VALUE #( %tky = ls_char-%tky ) TO failed-inspectionchar.
        APPEND VALUE #( %tky = ls_char-%tky
                        %msg = new_message_with_text(
                                 severity = if_abap_behv_message=>severity-error
                                 text     = ls_return-message ) )
               TO reported-inspectionchar.
        lsc_InspectionChar=>gv_error = abap_true.
      ELSE.
        lsc_InspectionChar=>gv_posted = abap_true.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.

CLASS lsc_InspectionChar IMPLEMENTATION.
  METHOD save.
    " Commit only when every filled-in characteristic posted cleanly.
    IF gv_error = abap_true.
      CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.
    ELSEIF gv_posted = abap_true.
      CALL FUNCTION 'BAPI_TRANSACTION_COMMIT' EXPORTING wait = abap_true.
    ENDIF.
    CLEAR: gv_posted, gv_error.
  ENDMETHOD.
ENDCLASS.
