CLASS lhc_DigSign DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS setDefaults FOR DETERMINE ON MODIFY
      IMPORTING keys FOR DigSign~setDefaults.
    METHODS validateKey FOR VALIDATE ON SAVE
      IMPORTING keys FOR DigSign~validateKey.
ENDCLASS.

CLASS lhc_DigSign IMPLEMENTATION.

  METHOD setDefaults.
    READ ENTITIES OF zi_digital-signature IN LOCAL MODE
      ENTITY DigSign FIELDS ( IsActive ) WITH CORRESPONDING #( keys )
      RESULT DATA(rows).
    MODIFY ENTITIES OF zi_digital-signature IN LOCAL MODE
      ENTITY DigSign UPDATE FIELDS ( IsActive )
        WITH VALUE #( FOR r IN rows (
          %tky     = r-%tky
          IsActive = COND #( WHEN r-IsActive IS INITIAL THEN abap_true ELSE r-IsActive ) ) )
      REPORTED DATA(upd).
  ENDMETHOD.

  METHOD validateKey.
    READ ENTITIES OF zi_digital-signature IN LOCAL MODE
      ENTITY DigSign FIELDS ( SignatoryId ) WITH CORRESPONDING #( keys )
      RESULT DATA(rows).
    LOOP AT rows INTO DATA(row).
      IF row-SignatoryId IS INITIAL.
        APPEND VALUE #( %tky = row-%tky ) TO failed-digsign.
        APPEND VALUE #( %tky = row-%tky
                        %msg = new_message_with_text(
                                 severity = if_abap_behv_message=>severity-error
                                 text     = 'SignatoryId is required' )
                        %element-SignatoryId = if_abap_behv=>mk-on ) TO reported-digsign.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
