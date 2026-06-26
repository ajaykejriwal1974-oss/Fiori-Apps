CLASS lhc_Job DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS setDefaults FOR DETERMINE ON MODIFY
      IMPORTING keys FOR Job~setDefaults.
    METHODS validateKey FOR VALIDATE ON SAVE
      IMPORTING keys FOR Job~validateKey.
ENDCLASS.

CLASS lhc_Job IMPLEMENTATION.

  METHOD setDefaults.
    READ ENTITIES OF zi_job IN LOCAL MODE
      ENTITY Job FIELDS ( CreatedOnDate CreatedAtTime LastChangedDate LastChangedTime ) WITH CORRESPONDING #( keys )
      RESULT DATA(rows).
    MODIFY ENTITIES OF zi_job IN LOCAL MODE
      ENTITY Job UPDATE FIELDS ( CreatedOnDate CreatedAtTime LastChangedDate LastChangedTime )
        WITH VALUE #( FOR r IN rows ( %tky = r-%tky
          CreatedOnDate = COND #( WHEN r-CreatedOnDate IS INITIAL THEN sy-datum ELSE r-CreatedOnDate )
          CreatedAtTime = COND #( WHEN r-CreatedAtTime IS INITIAL THEN sy-uzeit ELSE r-CreatedAtTime )
          LastChangedDate = sy-datum
          LastChangedTime = sy-uzeit ) ) )
      REPORTED DATA(upd).
  ENDMETHOD.

  METHOD validateKey.
    READ ENTITIES OF zi_job IN LOCAL MODE
      ENTITY Job FIELDS ( JobNumber ) WITH CORRESPONDING #( keys )
      RESULT DATA(rows).
    LOOP AT rows INTO DATA(row).
      IF row-JobNumber IS INITIAL.
        APPEND VALUE #( %tky = row-%tky ) TO failed-job.
        APPEND VALUE #( %tky = row-%tky
                        %msg = new_message_with_text(
                                 severity = if_abap_behv_message=>severity-error
                                 text     = 'JobNumber is required' )
                        %element-JobNumber = if_abap_behv=>mk-on ) TO reported-job.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
