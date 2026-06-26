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
      ENTITY Recipe FIELDS ( CreatedOnDate CreatedAtTime LastChangedDate LastChangedTime ) WITH CORRESPONDING #( keys )
      RESULT DATA(rows).
    MODIFY ENTITIES OF zi_recipe IN LOCAL MODE
      ENTITY Recipe UPDATE FIELDS ( CreatedOnDate CreatedAtTime LastChangedDate LastChangedTime )
        WITH VALUE #( FOR r IN rows ( %tky = r-%tky
          CreatedOnDate = COND #( WHEN r-CreatedOnDate IS INITIAL THEN sy-datum ELSE r-CreatedOnDate )
          CreatedAtTime = COND #( WHEN r-CreatedAtTime IS INITIAL THEN sy-uzeit ELSE r-CreatedAtTime )
          LastChangedDate = sy-datum
          LastChangedTime = sy-uzeit ) ) )
      REPORTED DATA(upd).
  ENDMETHOD.

  METHOD validateKey.
    READ ENTITIES OF zi_recipe IN LOCAL MODE
      ENTITY Recipe FIELDS ( Plant ) WITH CORRESPONDING #( keys )
      RESULT DATA(rows).
    LOOP AT rows INTO DATA(row).
      IF row-Plant IS INITIAL.
        APPEND VALUE #( %tky = row-%tky ) TO failed-recipe.
        APPEND VALUE #( %tky = row-%tky
                        %msg = new_message_with_text(
                                 severity = if_abap_behv_message=>severity-error
                                 text     = 'Plant is required' )
                        %element-Plant = if_abap_behv=>mk-on ) TO reported-recipe.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
