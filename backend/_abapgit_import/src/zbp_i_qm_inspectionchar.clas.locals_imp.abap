CLASS lsc_InspectionChar DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PUBLIC SECTION.
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
    APPEND LINES OF entities TO lsc_InspectionChar=>gt_buffer.
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
      IF ls_char-ResultValue IS INITIAL AND ls_char-Valuation IS INITIAL.
        CONTINUE.
      ENDIF.

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
      " The QM results engine (SAPLQEEM) issues its own COMMIT WORK, which RAP
      " forbids inside its LUW. Run the BAPI in a separate LUW via aRFC so the
      " engine commits there; the RAP transaction is untouched. The BAPI is
      " self-committing, so no BAPI_TRANSACTION_COMMIT is needed.
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
