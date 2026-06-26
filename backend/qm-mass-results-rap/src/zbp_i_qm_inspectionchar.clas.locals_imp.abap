*"* Unmanaged behavior implementation for ZI_QM_InspectionChar.
*"*
*"* Flow: the UI edits ResultValue / Valuation per row (UPDATE) and submits the
*"* batch. The handler buffers the edited rows; the saver records them through
*"* the QM result-recording API and commits once.

CLASS lhc_InspectionChar DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS update FOR MODIFY
      IMPORTING entities FOR UPDATE InspectionChar.
ENDCLASS.

CLASS lhc_InspectionChar IMPLEMENTATION.
  METHOD update.
    " Buffer each edited characteristic for the save sequence.
    LOOP AT entities INTO DATA(ls_entity).
      lsc_InspectionChar=>add_to_buffer( ls_entity ).
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.


CLASS lsc_InspectionChar DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PUBLIC SECTION.
    CLASS-METHODS add_to_buffer
      IMPORTING is_char TYPE STRUCTURE FOR UPDATE zi_qm_inspectionchar.

  PROTECTED SECTION.
    METHODS save_modified    REDEFINITION.
    METHODS cleanup_finalize REDEFINITION.

  PRIVATE SECTION.
    CLASS-DATA gt_buffer TYPE TABLE FOR UPDATE zi_qm_inspectionchar.
ENDCLASS.

CLASS lsc_InspectionChar IMPLEMENTATION.

  METHOD add_to_buffer.
    APPEND is_char TO gt_buffer.
  ENDMETHOD.

  METHOD save_modified.
    DATA lv_commit_needed TYPE abap_bool.

    LOOP AT gt_buffer INTO DATA(ls_char).
      " Skip rows the user did not actually fill in.
      IF ls_char-ResultValue IS INITIAL AND ls_char-Valuation IS INITIAL.
        CONTINUE.
      ENDIF.

      " Record the characteristic result via the QM API, then close it.
      " VERIFY the exact BAPI parameter structure (bapi2045d4 fields) for your release.
      CALL FUNCTION 'BAPI_INSPCHAR_SETRESULT'
        EXPORTING insplot     = ls_char-InspectionLot
                  inspoper    = ls_char-InspectionOperation
                  inspchar    = ls_char-InspectionCharacteristic
                  char_result = VALUE bapi2045d4( mean_value = ls_char-ResultValue
                                                  evaluation = ls_char-Valuation )
        IMPORTING return      = DATA(ls_return).

      IF ls_return-type = 'E' OR ls_return-type = 'A'.
        APPEND VALUE #( %tky = VALUE #( InspectionLot           = ls_char-InspectionLot
                                        InspectionOperation     = ls_char-InspectionOperation
                                        InspectionCharacteristic = ls_char-InspectionCharacteristic )
                        %msg = new_message( id = ls_return-id number = ls_return-number
                                            severity = if_abap_behv_message=>severity-error
                                            v1 = ls_return-message_v1 v2 = ls_return-message_v2
                                            v3 = ls_return-message_v3 v4 = ls_return-message_v4 ) )
          TO reported-inspectionchar.
        CONTINUE.
      ENDIF.

      " Close the characteristic once recorded.
      CALL FUNCTION 'BAPI_INSPCHAR_CLOSE'
        EXPORTING insplot  = ls_char-InspectionLot
                  inspoper = ls_char-InspectionOperation
                  inspchar = ls_char-InspectionCharacteristic
        IMPORTING return   = ls_return.

      lv_commit_needed = abap_true.
    ENDLOOP.

    IF lv_commit_needed = abap_true.
      CALL FUNCTION 'BAPI_TRANSACTION_COMMIT' EXPORTING wait = abap_true.
    ENDIF.
  ENDMETHOD.

  METHOD cleanup_finalize.
    CLEAR gt_buffer.
  ENDMETHOD.

ENDCLASS.
