CLASS lhc_CForm DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS validateKey FOR VALIDATE ON SAVE
      IMPORTING keys FOR CForm~validateKey.
ENDCLASS.

CLASS lhc_CForm IMPLEMENTATION.

  METHOD validateKey.
    READ ENTITIES OF zi_cform IN LOCAL MODE
      ENTITY CForm FIELDS ( SalesOrganization ) WITH CORRESPONDING #( keys )
      RESULT DATA(rows).
    LOOP AT rows INTO DATA(row).
      IF row-SalesOrganization IS INITIAL.
        APPEND VALUE #( %tky = row-%tky ) TO failed-cform.
        APPEND VALUE #( %tky = row-%tky
                        %msg = new_message_with_text(
                                 severity = if_abap_behv_message=>severity-error
                                 text     = 'SalesOrganization is required' )
                        %element-SalesOrganization = if_abap_behv=>mk-on ) TO reported-cform.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
