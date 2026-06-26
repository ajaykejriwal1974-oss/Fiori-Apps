CLASS lhc_DigiSign DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS validateKey FOR VALIDATE ON SAVE
      IMPORTING keys FOR DigiSign~validateKey.
ENDCLASS.

CLASS lhc_DigiSign IMPLEMENTATION.

  METHOD validateKey.
    READ ENTITIES OF zi_digital_signature IN LOCAL MODE
      ENTITY DigiSign FIELDS ( CompanyCode ) WITH CORRESPONDING #( keys )
      RESULT DATA(rows).
    LOOP AT rows INTO DATA(row).
      IF row-CompanyCode IS INITIAL.
        APPEND VALUE #( %tky = row-%tky ) TO failed-digisign.
        APPEND VALUE #( %tky = row-%tky
                        %msg = new_message_with_text(
                                 severity = if_abap_behv_message=>severity-error
                                 text     = 'CompanyCode is required' )
                        %element-CompanyCode = if_abap_behv=>mk-on ) TO reported-digisign.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
