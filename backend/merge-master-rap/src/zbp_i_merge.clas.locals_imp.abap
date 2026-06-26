CLASS lhc_Merge DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS validateKey FOR VALIDATE ON SAVE
      IMPORTING keys FOR Merge~validateKey.
ENDCLASS.

CLASS lhc_Merge IMPLEMENTATION.

  METHOD validateKey.
    READ ENTITIES OF zi_merge IN LOCAL MODE
      ENTITY Merge FIELDS ( OrderNumber ) WITH CORRESPONDING #( keys )
      RESULT DATA(rows).
    LOOP AT rows INTO DATA(row).
      IF row-OrderNumber IS INITIAL.
        APPEND VALUE #( %tky = row-%tky ) TO failed-merge.
        APPEND VALUE #( %tky = row-%tky
                        %msg = new_message_with_text(
                                 severity = if_abap_behv_message=>severity-error
                                 text     = 'OrderNumber is required' )
                        %element-OrderNumber = if_abap_behv=>mk-on ) TO reported-merge.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
