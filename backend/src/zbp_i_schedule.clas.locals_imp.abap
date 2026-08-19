CLASS lhc_schedule DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS setadmindata FOR DETERMINE ON SAVE
      IMPORTING keys FOR Schedule~setAdminData.
ENDCLASS.

CLASS lhc_schedule IMPLEMENTATION.
  METHOD setadmindata.
    " Auto-fill the read-only admin dates/times (the user semantics fill created/
    " changed BY; these DATS+TIMS legacy columns have no timestamp annotation, so
    " they are set here). On create: stamp created + changed; on update: changed.
    DATA(lv_today) = cl_abap_context_info=>get_system_date( ).
    GET TIME.
    DATA(lv_now) = sy-uzeit.

    READ ENTITIES OF zi_schedule IN LOCAL MODE
      ENTITY Schedule FIELDS ( CreatedOnDate ) WITH CORRESPONDING #( keys )
      RESULT DATA(lt_sched).

    DATA lt_upd TYPE TABLE FOR UPDATE zi_schedule.
    LOOP AT lt_sched INTO DATA(ls).
      IF ls-CreatedOnDate IS INITIAL.
        APPEND VALUE #( %tky            = ls-%tky
                        CreatedOnDate   = lv_today
                        CreatedAtTime   = lv_now
                        LastChangedDate = lv_today
                        LastChangedTime = lv_now ) TO lt_upd.
      ELSE.
        APPEND VALUE #( %tky            = ls-%tky
                        LastChangedDate = lv_today
                        LastChangedTime = lv_now ) TO lt_upd.
      ENDIF.
    ENDLOOP.

    MODIFY ENTITIES OF zi_schedule IN LOCAL MODE
      ENTITY Schedule
        UPDATE FIELDS ( CreatedOnDate CreatedAtTime LastChangedDate LastChangedTime )
        WITH CORRESPONDING #( lt_upd )
      REPORTED DATA(lt_rep).
  ENDMETHOD.
ENDCLASS.
