CLASS lhc_MinMax DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS setDefaults FOR DETERMINE ON MODIFY
      IMPORTING keys FOR MinMax~setDefaults.
    METHODS validateKey FOR VALIDATE ON SAVE
      IMPORTING keys FOR MinMax~validateKey.
ENDCLASS.

CLASS lhc_MinMax IMPLEMENTATION.

  METHOD setDefaults.
    READ ENTITIES OF zi_minmax IN LOCAL MODE
      ENTITY MinMax FIELDS ( IsActive ) WITH CORRESPONDING #( keys )
      RESULT DATA(rows).
    MODIFY ENTITIES OF zi_minmax IN LOCAL MODE
      ENTITY MinMax UPDATE FIELDS ( IsActive )
        WITH VALUE #( FOR r IN rows (
          %tky     = r-%tky
          IsActive = COND #( WHEN r-IsActive IS INITIAL THEN abap_true ELSE r-IsActive ) ) )
      REPORTED DATA(upd).
  ENDMETHOD.

  METHOD validateKey.
    READ ENTITIES OF zi_minmax IN LOCAL MODE
      ENTITY MinMax FIELDS ( Material ) WITH CORRESPONDING #( keys )
      RESULT DATA(rows).
    LOOP AT rows INTO DATA(row).
      IF row-Material IS INITIAL.
        APPEND VALUE #( %tky = row-%tky ) TO failed-minmax.
        APPEND VALUE #( %tky = row-%tky
                        %msg = new_message_with_text(
                                 severity = if_abap_behv_message=>severity-error
                                 text     = 'Material is required' )
                        %element-Material = if_abap_behv=>mk-on ) TO reported-minmax.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
