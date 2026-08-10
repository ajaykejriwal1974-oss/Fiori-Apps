CLASS lhc_job DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS setadmindata FOR DETERMINE ON SAVE
      IMPORTING keys FOR Job~setAdminData.
ENDCLASS.

CLASS lhc_job IMPLEMENTATION.
  METHOD setadmindata.
    DATA(lv_today) = cl_abap_context_info=>get_system_date( ).
    GET TIME.
    DATA(lv_now) = sy-uzeit.
    READ ENTITIES OF zi_job IN LOCAL MODE
      ENTITY Job FIELDS ( CreatedOnDate ) WITH CORRESPONDING #( keys )
      RESULT DATA(lt).
    DATA lt_upd TYPE TABLE FOR UPDATE zi_job.
    LOOP AT lt INTO DATA(ls).
      IF ls-CreatedOnDate IS INITIAL.
        APPEND VALUE #( %tky = ls-%tky CreatedOnDate = lv_today CreatedAtTime = lv_now
                        LastChangedDate = lv_today LastChangedTime = lv_now ) TO lt_upd.
      ELSE.
        APPEND VALUE #( %tky = ls-%tky LastChangedDate = lv_today LastChangedTime = lv_now ) TO lt_upd.
      ENDIF.
    ENDLOOP.
    MODIFY ENTITIES OF zi_job IN LOCAL MODE
      ENTITY Job UPDATE FIELDS ( CreatedOnDate CreatedAtTime LastChangedDate LastChangedTime )
      WITH CORRESPONDING #( lt_upd ) REPORTED DATA(lt_rep).
  ENDMETHOD.
ENDCLASS.
