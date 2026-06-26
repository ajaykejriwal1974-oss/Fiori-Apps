CLASS lhc_Truck DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS setDefaults FOR DETERMINE ON MODIFY
      IMPORTING keys FOR Truck~setDefaults.
    METHODS validateKey FOR VALIDATE ON SAVE
      IMPORTING keys FOR Truck~validateKey.
ENDCLASS.

CLASS lhc_Truck IMPLEMENTATION.

  METHOD setDefaults.
    READ ENTITIES OF zi_truck IN LOCAL MODE
      ENTITY Truck FIELDS ( IsActive ) WITH CORRESPONDING #( keys )
      RESULT DATA(rows).
    MODIFY ENTITIES OF zi_truck IN LOCAL MODE
      ENTITY Truck UPDATE FIELDS ( IsActive )
        WITH VALUE #( FOR r IN rows (
          %tky     = r-%tky
          IsActive = COND #( WHEN r-IsActive IS INITIAL THEN abap_true ELSE r-IsActive ) ) )
      REPORTED DATA(upd).
  ENDMETHOD.

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
