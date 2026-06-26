CLASS lhc_Recipe DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS setDefaults FOR DETERMINE ON MODIFY
      IMPORTING keys FOR Recipe~setDefaults.
    METHODS validateKey FOR VALIDATE ON SAVE
      IMPORTING keys FOR Recipe~validateKey.
ENDCLASS.

CLASS lhc_Recipe IMPLEMENTATION.

  METHOD setDefaults.
    READ ENTITIES OF zi_recipe IN LOCAL MODE
      ENTITY Recipe FIELDS ( IsActive ) WITH CORRESPONDING #( keys )
      RESULT DATA(rows).
    MODIFY ENTITIES OF zi_recipe IN LOCAL MODE
      ENTITY Recipe UPDATE FIELDS ( IsActive )
        WITH VALUE #( FOR r IN rows (
          %tky     = r-%tky
          IsActive = COND #( WHEN r-IsActive IS INITIAL THEN abap_true ELSE r-IsActive ) ) )
      REPORTED DATA(upd).
  ENDMETHOD.

  METHOD validateKey.
    READ ENTITIES OF zi_recipe IN LOCAL MODE
      ENTITY Recipe FIELDS ( RecipeCode ) WITH CORRESPONDING #( keys )
      RESULT DATA(rows).
    LOOP AT rows INTO DATA(row).
      IF row-RecipeCode IS INITIAL.
        APPEND VALUE #( %tky = row-%tky ) TO failed-recipe.
        APPEND VALUE #( %tky = row-%tky
                        %msg = new_message_with_text(
                                 severity = if_abap_behv_message=>severity-error
                                 text     = 'RecipeCode is required' )
                        %element-RecipeCode = if_abap_behv=>mk-on ) TO reported-recipe.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
