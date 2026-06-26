CLASS lhc_PackMaterial DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS setDefaults FOR DETERMINE ON MODIFY
      IMPORTING keys FOR PackMaterial~setDefaults.
    METHODS validateKey FOR VALIDATE ON SAVE
      IMPORTING keys FOR PackMaterial~validateKey.
ENDCLASS.

CLASS lhc_PackMaterial IMPLEMENTATION.

  METHOD setDefaults.
    READ ENTITIES OF zi_packing-material IN LOCAL MODE
      ENTITY PackMaterial FIELDS ( IsActive ) WITH CORRESPONDING #( keys )
      RESULT DATA(rows).
    MODIFY ENTITIES OF zi_packing-material IN LOCAL MODE
      ENTITY PackMaterial UPDATE FIELDS ( IsActive )
        WITH VALUE #( FOR r IN rows (
          %tky     = r-%tky
          IsActive = COND #( WHEN r-IsActive IS INITIAL THEN abap_true ELSE r-IsActive ) ) )
      REPORTED DATA(upd).
  ENDMETHOD.

  METHOD validateKey.
    READ ENTITIES OF zi_packing-material IN LOCAL MODE
      ENTITY PackMaterial FIELDS ( PackingMaterial ) WITH CORRESPONDING #( keys )
      RESULT DATA(rows).
    LOOP AT rows INTO DATA(row).
      IF row-PackingMaterial IS INITIAL.
        APPEND VALUE #( %tky = row-%tky ) TO failed-packmaterial.
        APPEND VALUE #( %tky = row-%tky
                        %msg = new_message_with_text(
                                 severity = if_abap_behv_message=>severity-error
                                 text     = 'PackingMaterial is required' )
                        %element-PackingMaterial = if_abap_behv=>mk-on ) TO reported-packmaterial.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
