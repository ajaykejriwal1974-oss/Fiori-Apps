CLASS lhc_Truck DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS validateKey FOR VALIDATE ON SAVE
      IMPORTING keys FOR Truck~validateKey.
ENDCLASS.

CLASS lhc_Truck IMPLEMENTATION.

  METHOD validateKey.
    READ ENTITIES OF zi_truck IN LOCAL MODE
      ENTITY Truck FIELDS ( TruckNumber ) WITH CORRESPONDING #( keys )
      RESULT DATA(rows).
    LOOP AT rows INTO DATA(row).
      IF row-TruckNumber IS INITIAL.
        APPEND VALUE #( %tky = row-%tky ) TO failed-truck.
        APPEND VALUE #( %tky = row-%tky
                        %msg = new_message_with_text(
                                 severity = if_abap_behv_message=>severity-error
                                 text     = 'TruckNumber is required' )
                        %element-TruckNumber = if_abap_behv=>mk-on ) TO reported-truck.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
