*"* Behaviour implementation for ZI_QC_INSP_LOT.
*"*
*"* Writes go through the standard QM BAPIs. Nothing here updates QAMR
*"* directly: the BAPI owns valuation against the selected set, the sample
*"* arithmetic, and the status transitions, and reproducing that by hand would
*"* be both wrong and unsupported.
*"*
*"* COMMIT is issued via DESTINATION 'NONE' - the same pattern used in
*"* ZBP_I_PROD_CONFIRMATION. It separates the update-task LUW so that one
*"* failing characteristic does not roll back the whole set of results the
*"* technician just entered.

CLASS lhc_characteristic DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR Characteristic RESULT result.
    METHODS update FOR MODIFY IMPORTING entities FOR UPDATE Characteristic.
ENDCLASS.

CLASS lhc_characteristic IMPLEMENTATION.

  METHOD get_global_authorizations.
  ENDMETHOD.

  METHOD update.

    DATA lt_char   TYPE STANDARD TABLE OF bapi2045l2.
    DATA lt_return TYPE STANDARD TABLE OF bapiret2.

    LOOP AT entities ASSIGNING FIELD-SYMBOL(<e>).

      CLEAR: lt_char, lt_return.

      " Read the specification so we know whether this characteristic is
      " quantitative or qualitative. Guessing from which field the UI filled
      " would break the moment a technician enters 0 as a legitimate value.
      SELECT SINGLE katalgart1, stellen
        FROM qamv
        INTO @DATA(ls_spec)
        WHERE prueflos = @<e>-InspectionLot
          AND vorglfnr = @<e>-OperationNumber
          AND merknr   = @<e>-CharacteristicNumber.

      IF sy-subrc <> 0.
        APPEND VALUE #( %tky = <e>-%tky
                        %msg = new_message_with_text(
                                 severity = if_abap_behv_message=>severity-error
                                 text     = |Characteristic not found in inspection lot| ) )
               TO reported-characteristic.
        APPEND VALUE #( %tky = <e>-%tky ) TO failed-characteristic.
        CONTINUE.
      ENDIF.

      DATA(ls_row) = VALUE bapi2045l2(
        insplot   = <e>-InspectionLot
        inspoper  = <e>-OperationNumber
        inspchar  = <e>-CharacteristicNumber ).

      IF ls_spec-katalgart1 IS NOT INITIAL.
        " Qualitative - the result is a code from the selected set
        ls_row-code1     = <e>-ResultCode.
        ls_row-code_grp1 = <e>-ResultCodeGroup.
      ELSE.
        " Quantitative - mean value
        ls_row-mean_value = <e>-MeanValue.
      ENDIF.

      " Attribute characteristics carry a defect count over the sample rather
      " than one row per unit inspected. This is the field that keeps stage 3
      " at ~9 entries per lot instead of ~2400 per day.
      IF <e>-DefectCount IS NOT INITIAL OR <e>-ActualSampleSize IS NOT INITIAL.
        ls_row-nonconformfeatures = <e>-DefectCount.
        ls_row-insp_scope         = <e>-ActualSampleSize.
      ENDIF.

      ls_row-evaluated = abap_true.
      APPEND ls_row TO lt_char.

      CALL FUNCTION 'BAPI_INSPCHAR_SETRESULT'
        EXPORTING
          insplot          = CONV qplos( <e>-InspectionLot )
          inspoper         = CONV qlfnkn( <e>-OperationNumber )
        TABLES
          char_results     = lt_char
          return           = lt_return.

      LOOP AT lt_return ASSIGNING FIELD-SYMBOL(<r>) WHERE type CA 'EAX'.
        APPEND VALUE #( %tky = <e>-%tky
                        %msg = new_message( id       = <r>-id
                                            number   = <r>-number
                                            severity = if_abap_behv_message=>severity-error
                                            v1 = <r>-message_v1 v2 = <r>-message_v2
                                            v3 = <r>-message_v3 v4 = <r>-message_v4 ) )
               TO reported-characteristic.
        APPEND VALUE #( %tky = <e>-%tky ) TO failed-characteristic.
      ENDLOOP.

      IF NOT line_exists( failed-characteristic[ %tky = <e>-%tky ] ).
        CALL FUNCTION 'BAPI_TRANSACTION_COMMIT' DESTINATION 'NONE'
          EXPORTING wait = abap_true.
      ELSE.
        CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK' DESTINATION 'NONE'.
      ENDIF.

    ENDLOOP.

  ENDMETHOD.

ENDCLASS.


CLASS lhc_inspectionlot DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR InspectionLot RESULT result.

    METHODS recordResults FOR MODIFY
      IMPORTING keys FOR ACTION InspectionLot~recordResults RESULT result.

    METHODS setUsageDecision FOR MODIFY
      IMPORTING keys FOR ACTION InspectionLot~setUsageDecision RESULT result.

    METHODS read_lot IMPORTING iv_lot TYPE qplos RETURNING VALUE(rs) TYPE zi_qc_insp_lot.
ENDCLASS.

CLASS lhc_inspectionlot IMPLEMENTATION.

  METHOD get_global_authorizations.
  ENDMETHOD.

  METHOD read_lot.
    SELECT SINGLE * FROM zi_qc_insp_lot INTO @rs WHERE InspectionLot = @iv_lot.
  ENDMETHOD.

  METHOD recordResults.

    DATA lt_return TYPE STANDARD TABLE OF bapiret2.

    LOOP AT keys ASSIGNING FIELD-SYMBOL(<k>).

      CLEAR lt_return.

      CALL FUNCTION 'BAPI_INSPOPER_RECORDRESULTS'
        EXPORTING
          insplot  = CONV qplos( <k>-InspectionLot )
          inspoper = CONV qlfnkn( <k>-%param-OperationNumber )
        TABLES
          return   = lt_return.

      DATA(lv_failed) = abap_false.
      LOOP AT lt_return ASSIGNING FIELD-SYMBOL(<r>) WHERE type CA 'EAX'.
        lv_failed = abap_true.
        APPEND VALUE #( %tky = <k>-%tky
                        %msg = new_message( id       = <r>-id
                                            number   = <r>-number
                                            severity = if_abap_behv_message=>severity-error
                                            v1 = <r>-message_v1 v2 = <r>-message_v2
                                            v3 = <r>-message_v3 v4 = <r>-message_v4 ) )
               TO reported-inspectionlot.
      ENDLOOP.

      IF lv_failed = abap_true.
        CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK' DESTINATION 'NONE'.
        APPEND VALUE #( %tky = <k>-%tky ) TO failed-inspectionlot.
        CONTINUE.
      ENDIF.

      CALL FUNCTION 'BAPI_TRANSACTION_COMMIT' DESTINATION 'NONE'
        EXPORTING wait = abap_true.

      APPEND VALUE #( %tky   = <k>-%tky
                      %param = read_lot( CONV qplos( <k>-InspectionLot ) ) ) TO result.
    ENDLOOP.

  ENDMETHOD.

  METHOD setUsageDecision.

    DATA lt_return TYPE STANDARD TABLE OF bapiret2.

    LOOP AT keys ASSIGNING FIELD-SYMBOL(<k>).

      CLEAR lt_return.

      IF <k>-%param-Code IS INITIAL OR <k>-%param-CodeGroup IS INITIAL.
        APPEND VALUE #( %tky = <k>-%tky
                        %msg = new_message_with_text(
                                 severity = if_abap_behv_message=>severity-error
                                 text     = |Usage decision code and code group are required| ) )
               TO reported-inspectionlot.
        APPEND VALUE #( %tky = <k>-%tky ) TO failed-inspectionlot.
        CONTINUE.
      ENDIF.

      " A re-dye or strip decision blocks the batch and hands over to the
      " existing loop: WIP Batch Close reopen, then Cancel Production
      " Confirmation. The app tells the technician; it does not do it for them,
      " because reopening a batch is a decision with stock consequences.
      DATA(ls_ud) = VALUE bapi2045d2(
        ud_selected_set  = 'ZQC_UD'
        ud_plant         = read_lot( CONV qplos( <k>-InspectionLot ) )-Plant
        ud_code_group    = <k>-%param-CodeGroup
        ud_code          = <k>-%param-Code
        ud_description   = <k>-%param-Reason ).

      CALL FUNCTION 'BAPI_INSPLOT_SETUSAGEDECISION'
        EXPORTING
          number          = CONV qplos( <k>-InspectionLot )
          usagedecision   = ls_ud
        TABLES
          return          = lt_return.

      DATA(lv_bad) = abap_false.
      LOOP AT lt_return ASSIGNING FIELD-SYMBOL(<r2>) WHERE type CA 'EAX'.
        lv_bad = abap_true.
        APPEND VALUE #( %tky = <k>-%tky
                        %msg = new_message( id       = <r2>-id
                                            number   = <r2>-number
                                            severity = if_abap_behv_message=>severity-error
                                            v1 = <r2>-message_v1 v2 = <r2>-message_v2
                                            v3 = <r2>-message_v3 v4 = <r2>-message_v4 ) )
               TO reported-inspectionlot.
      ENDLOOP.

      IF lv_bad = abap_true.
        CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK' DESTINATION 'NONE'.
        APPEND VALUE #( %tky = <k>-%tky ) TO failed-inspectionlot.
        CONTINUE.
      ENDIF.

      CALL FUNCTION 'BAPI_TRANSACTION_COMMIT' DESTINATION 'NONE'
        EXPORTING wait = abap_true.

      APPEND VALUE #( %tky   = <k>-%tky
                      %param = read_lot( CONV qplos( <k>-InspectionLot ) ) ) TO result.
    ENDLOOP.

  ENDMETHOD.

ENDCLASS.
