CLASS lhc_CheckedBy DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS setDefaults FOR DETERMINE ON MODIFY
      IMPORTING keys FOR CheckedBy~setDefaults.
    METHODS validateKey FOR VALIDATE ON SAVE
      IMPORTING keys FOR CheckedBy~validateKey.
ENDCLASS.

CLASS lhc_CheckedBy IMPLEMENTATION.

  METHOD setDefaults.
    READ ENTITIES OF zi_checked-by IN LOCAL MODE
      ENTITY CheckedBy FIELDS ( IsActive ) WITH CORRESPONDING #( keys )
      RESULT DATA(rows).
    MODIFY ENTITIES OF zi_checked-by IN LOCAL MODE
      ENTITY CheckedBy UPDATE FIELDS ( IsActive )
        WITH VALUE #( FOR r IN rows (
          %tky     = r-%tky
          IsActive = COND #( WHEN r-IsActive IS INITIAL THEN abap_true ELSE r-IsActive ) ) )
      REPORTED DATA(upd).
  ENDMETHOD.

  METHOD validateKey.
    READ ENTITIES OF zi_checked-by IN LOCAL MODE
      ENTITY CheckedBy FIELDS ( OperatorId ) WITH CORRESPONDING #( keys )
      RESULT DATA(rows).
    LOOP AT rows INTO DATA(row).
      IF row-OperatorId IS INITIAL.
        APPEND VALUE #( %tky = row-%tky ) TO failed-checkedby.
        APPEND VALUE #( %tky = row-%tky
                        %msg = new_message_with_text(
                                 severity = if_abap_behv_message=>severity-error
                                 text     = 'OperatorId is required' )
                        %element-OperatorId = if_abap_behv=>mk-on ) TO reported-checkedby.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
