CLASS lhc_Shade DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS setDefaults FOR DETERMINE ON MODIFY
      IMPORTING keys FOR Shade~setDefaults.

    METHODS validateShade FOR VALIDATE ON SAVE
      IMPORTING keys FOR Shade~validateShade.
ENDCLASS.

CLASS lhc_Shade IMPLEMENTATION.

  METHOD setDefaults.
    " Default IsActive = true on create; normalise ColorFamily to upper case.
    READ ENTITIES OF zi_dd_shade IN LOCAL MODE
      ENTITY Shade
        FIELDS ( IsActive ColorFamily )
        WITH CORRESPONDING #( keys )
      RESULT DATA(shades).

    MODIFY ENTITIES OF zi_dd_shade IN LOCAL MODE
      ENTITY Shade
        UPDATE FIELDS ( IsActive ColorFamily )
        WITH VALUE #( FOR s IN shades (
          %tky        = s-%tky
          IsActive    = COND #( WHEN s-IsActive IS INITIAL THEN abap_true ELSE s-IsActive )
          ColorFamily = to_upper( s-ColorFamily ) ) )
      REPORTED DATA(update_reported).
  ENDMETHOD.

  METHOD validateShade.
    READ ENTITIES OF zi_dd_shade IN LOCAL MODE
      ENTITY Shade
        FIELDS ( ShadeCode RgbHex )
        WITH CORRESPONDING #( keys )
      RESULT DATA(shades).

    LOOP AT shades INTO DATA(shade).
      " Shade code is mandatory.
      IF shade-ShadeCode IS INITIAL.
        APPEND VALUE #( %tky = shade-%tky ) TO failed-shade.
        APPEND VALUE #( %tky               = shade-%tky
                        %msg               = new_message_with_text(
                                               severity = if_abap_behv_message=>severity-error
                                               text     = 'Shade code is required' )
                        %element-ShadeCode = if_abap_behv=>mk-on ) TO reported-shade.
      ENDIF.

      " RGB hex, when supplied, must be exactly 6 hexadecimal digits.
      IF shade-RgbHex IS NOT INITIAL
         AND ( strlen( shade-RgbHex ) <> 6
               OR shade-RgbHex CN '0123456789ABCDEFabcdef' ).
        APPEND VALUE #( %tky = shade-%tky ) TO failed-shade.
        APPEND VALUE #( %tky            = shade-%tky
                        %msg            = new_message_with_text(
                                            severity = if_abap_behv_message=>severity-error
                                            text     = 'RGB hex must be 6 hexadecimal digits' )
                        %element-RgbHex = if_abap_behv=>mk-on ) TO reported-shade.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
