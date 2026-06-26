CLASS lhc_PackMaterial DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS validateKey FOR VALIDATE ON SAVE
      IMPORTING keys FOR PackMaterial~validateKey.
ENDCLASS.

CLASS lhc_PackMaterial IMPLEMENTATION.

  METHOD validateKey.
    READ ENTITIES OF zi_packing_material IN LOCAL MODE
      ENTITY PackMaterial FIELDS ( PackingType ) WITH CORRESPONDING #( keys )
      RESULT DATA(rows).
    LOOP AT rows INTO DATA(row).
      IF row-PackingType IS INITIAL.
        APPEND VALUE #( %tky = row-%tky ) TO failed-packmaterial.
        APPEND VALUE #( %tky = row-%tky
                        %msg = new_message_with_text(
                                 severity = if_abap_behv_message=>severity-error
                                 text     = 'PackingType is required' )
                        %element-PackingType = if_abap_behv=>mk-on ) TO reported-packmaterial.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
