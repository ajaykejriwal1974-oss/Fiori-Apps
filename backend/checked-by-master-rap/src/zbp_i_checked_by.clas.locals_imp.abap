CLASS lhc_CheckedBy DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS validateKey FOR VALIDATE ON SAVE
      IMPORTING keys FOR CheckedBy~validateKey.
ENDCLASS.

CLASS lhc_CheckedBy IMPLEMENTATION.

  METHOD validateKey.
    READ ENTITIES OF zi_checked_by IN LOCAL MODE
      ENTITY CheckedBy FIELDS ( SerialNumber ) WITH CORRESPONDING #( keys )
      RESULT DATA(rows).
    LOOP AT rows INTO DATA(row).
      IF row-SerialNumber IS INITIAL.
        APPEND VALUE #( %tky = row-%tky ) TO failed-checkedby.
        APPEND VALUE #( %tky = row-%tky
                        %msg = new_message_with_text(
                                 severity = if_abap_behv_message=>severity-error
                                 text     = 'SerialNumber is required' )
                        %element-SerialNumber = if_abap_behv=>mk-on ) TO reported-checkedby.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
