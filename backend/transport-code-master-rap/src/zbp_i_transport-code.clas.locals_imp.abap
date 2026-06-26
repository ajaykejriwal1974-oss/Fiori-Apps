CLASS lhc_TransportCode DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS setDefaults FOR DETERMINE ON MODIFY
      IMPORTING keys FOR TransportCode~setDefaults.
    METHODS validateKey FOR VALIDATE ON SAVE
      IMPORTING keys FOR TransportCode~validateKey.
ENDCLASS.

CLASS lhc_TransportCode IMPLEMENTATION.

  METHOD setDefaults.
    READ ENTITIES OF zi_transport-code IN LOCAL MODE
      ENTITY TransportCode FIELDS ( IsActive ) WITH CORRESPONDING #( keys )
      RESULT DATA(rows).
    MODIFY ENTITIES OF zi_transport-code IN LOCAL MODE
      ENTITY TransportCode UPDATE FIELDS ( IsActive )
        WITH VALUE #( FOR r IN rows (
          %tky     = r-%tky
          IsActive = COND #( WHEN r-IsActive IS INITIAL THEN abap_true ELSE r-IsActive ) ) )
      REPORTED DATA(upd).
  ENDMETHOD.

  METHOD validateKey.
    READ ENTITIES OF zi_transport-code IN LOCAL MODE
      ENTITY TransportCode FIELDS ( TransportCode ) WITH CORRESPONDING #( keys )
      RESULT DATA(rows).
    LOOP AT rows INTO DATA(row).
      IF row-TransportCode IS INITIAL.
        APPEND VALUE #( %tky = row-%tky ) TO failed-transportcode.
        APPEND VALUE #( %tky = row-%tky
                        %msg = new_message_with_text(
                                 severity = if_abap_behv_message=>severity-error
                                 text     = 'TransportCode is required' )
                        %element-TransportCode = if_abap_behv=>mk-on ) TO reported-transportcode.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
