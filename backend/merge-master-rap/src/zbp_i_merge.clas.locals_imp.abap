CLASS lhc_Merge DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS setDefaults FOR DETERMINE ON MODIFY
      IMPORTING keys FOR Merge~setDefaults.
    METHODS validateKey FOR VALIDATE ON SAVE
      IMPORTING keys FOR Merge~validateKey.
ENDCLASS.

CLASS lhc_Merge IMPLEMENTATION.

  METHOD setDefaults.
    READ ENTITIES OF zi_merge IN LOCAL MODE
      ENTITY Merge FIELDS ( IsActive ) WITH CORRESPONDING #( keys )
      RESULT DATA(rows).
    MODIFY ENTITIES OF zi_merge IN LOCAL MODE
      ENTITY Merge UPDATE FIELDS ( IsActive )
        WITH VALUE #( FOR r IN rows (
          %tky     = r-%tky
          IsActive = COND #( WHEN r-IsActive IS INITIAL THEN abap_true ELSE r-IsActive ) ) )
      REPORTED DATA(upd).
  ENDMETHOD.

  METHOD validateKey.
    READ ENTITIES OF zi_merge IN LOCAL MODE
      ENTITY Merge FIELDS ( MergeId ) WITH CORRESPONDING #( keys )
      RESULT DATA(rows).
    LOOP AT rows INTO DATA(row).
      IF row-MergeId IS INITIAL.
        APPEND VALUE #( %tky = row-%tky ) TO failed-merge.
        APPEND VALUE #( %tky = row-%tky
                        %msg = new_message_with_text(
                                 severity = if_abap_behv_message=>severity-error
                                 text     = 'MergeId is required' )
                        %element-MergeId = if_abap_behv=>mk-on ) TO reported-merge.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
