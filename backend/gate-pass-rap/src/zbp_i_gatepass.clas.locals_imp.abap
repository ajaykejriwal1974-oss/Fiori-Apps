CLASS lhc_GatePass DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS setHeaderDefaults FOR DETERMINE ON MODIFY
      IMPORTING keys FOR GatePass~setHeaderDefaults.
    METHODS validateHeader FOR VALIDATE ON SAVE
      IMPORTING keys FOR GatePass~validateHeader.
ENDCLASS.

CLASS lhc_GatePass IMPLEMENTATION.

  METHOD setHeaderDefaults.
    READ ENTITIES OF zi_gatepass IN LOCAL MODE
      ENTITY GatePass FIELDS ( CreatedBy CreatedOnDate CreatedAtTime CreatedByUser FiscalYear )
        WITH CORRESPONDING #( keys )
      RESULT DATA(rows).
    MODIFY ENTITIES OF zi_gatepass IN LOCAL MODE
      ENTITY GatePass UPDATE FIELDS ( CreatedBy CreatedOnDate CreatedAtTime CreatedByUser FiscalYear )
        WITH VALUE #( FOR r IN rows ( %tky = r-%tky
          CreatedBy     = COND #( WHEN r-CreatedBy     IS INITIAL THEN sy-uname ELSE r-CreatedBy )
          CreatedByUser = COND #( WHEN r-CreatedByUser IS INITIAL THEN sy-uname ELSE r-CreatedByUser )
          CreatedOnDate = COND #( WHEN r-CreatedOnDate IS INITIAL THEN sy-datum ELSE r-CreatedOnDate )
          CreatedAtTime = COND #( WHEN r-CreatedAtTime IS INITIAL THEN sy-uzeit ELSE r-CreatedAtTime )
          FiscalYear    = COND #( WHEN r-FiscalYear    IS INITIAL THEN sy-datum(4) ELSE r-FiscalYear ) ) )
      REPORTED DATA(upd).
    " TODO: assign GpNumber from number-range object via ZGPASS_NUM
    "   (cl_numberrange_runtime=>number_get) keyed by Plant + FiscalYear.
  ENDMETHOD.

  METHOD validateHeader.
    READ ENTITIES OF zi_gatepass IN LOCAL MODE
      ENTITY GatePass FIELDS ( GpNumber DocumentType Plant ) WITH CORRESPONDING #( keys )
      RESULT DATA(rows).
    LOOP AT rows INTO DATA(row).
      IF row-DocumentType IS INITIAL OR row-Plant IS INITIAL.
        APPEND VALUE #( %tky = row-%tky ) TO failed-gatepass.
        APPEND VALUE #( %tky = row-%tky
                        %msg = new_message_with_text(
                                 severity = if_abap_behv_message=>severity-error
                                 text     = 'Document type and plant are required' )
                        %element-DocumentType = if_abap_behv=>mk-on
                        %element-Plant        = if_abap_behv=>mk-on ) TO reported-gatepass.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
