CLASS lhc_Transport DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS validateKey FOR VALIDATE ON SAVE
      IMPORTING keys FOR Transport~validateKey.
ENDCLASS.

CLASS lhc_Transport IMPLEMENTATION.

  METHOD validateKey.
    READ ENTITIES OF zi_transport IN LOCAL MODE
      ENTITY Transport FIELDS ( TransportCode ) WITH CORRESPONDING #( keys )
      RESULT DATA(rows).
    LOOP AT rows INTO DATA(row).
      IF row-TransportCode IS INITIAL.
        APPEND VALUE #( %tky = row-%tky ) TO failed-transport.
        APPEND VALUE #( %tky = row-%tky
                        %msg = new_message_with_text(
                                 severity = if_abap_behv_message=>severity-error
                                 text     = 'TransportCode is required' )
                        %element-TransportCode = if_abap_behv=>mk-on ) TO reported-transport.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
