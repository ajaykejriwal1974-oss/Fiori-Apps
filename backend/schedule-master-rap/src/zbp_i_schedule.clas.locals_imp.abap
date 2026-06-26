CLASS lhc_Schedule DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS setDefaults FOR DETERMINE ON MODIFY
      IMPORTING keys FOR Schedule~setDefaults.
    METHODS validateKey FOR VALIDATE ON SAVE
      IMPORTING keys FOR Schedule~validateKey.
ENDCLASS.

CLASS lhc_Schedule IMPLEMENTATION.

  METHOD setDefaults.
    READ ENTITIES OF zi_schedule IN LOCAL MODE
      ENTITY Schedule FIELDS ( IsActive ) WITH CORRESPONDING #( keys )
      RESULT DATA(rows).
    MODIFY ENTITIES OF zi_schedule IN LOCAL MODE
      ENTITY Schedule UPDATE FIELDS ( IsActive )
        WITH VALUE #( FOR r IN rows (
          %tky     = r-%tky
          IsActive = COND #( WHEN r-IsActive IS INITIAL THEN abap_true ELSE r-IsActive ) ) )
      REPORTED DATA(upd).
  ENDMETHOD.

  METHOD validateKey.
    READ ENTITIES OF zi_schedule IN LOCAL MODE
      ENTITY Schedule FIELDS ( ScheduleId ) WITH CORRESPONDING #( keys )
      RESULT DATA(rows).
    LOOP AT rows INTO DATA(row).
      IF row-ScheduleId IS INITIAL.
        APPEND VALUE #( %tky = row-%tky ) TO failed-schedule.
        APPEND VALUE #( %tky = row-%tky
                        %msg = new_message_with_text(
                                 severity = if_abap_behv_message=>severity-error
                                 text     = 'ScheduleId is required' )
                        %element-ScheduleId = if_abap_behv=>mk-on ) TO reported-schedule.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
