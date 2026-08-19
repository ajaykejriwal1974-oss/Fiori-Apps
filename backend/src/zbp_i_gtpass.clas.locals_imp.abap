CLASS lhc_gatepass DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS setadmindata FOR DETERMINE ON SAVE
      IMPORTING keys FOR GatePass~setAdminData.
ENDCLASS.

CLASS lhc_gatepass IMPLEMENTATION.
  METHOD setadmindata.
    DATA(lv_today) = cl_abap_context_info=>get_system_date( ).
    GET TIME.
    DATA(lv_now) = sy-uzeit.
    READ ENTITIES OF zi_gtpass IN LOCAL MODE
      ENTITY GatePass FIELDS ( CreatedOnDate ) WITH CORRESPONDING #( keys )
      RESULT DATA(lt).
    DATA lt_upd TYPE TABLE FOR UPDATE zi_gtpass.
    LOOP AT lt INTO DATA(ls).
      IF ls-CreatedOnDate IS INITIAL.
        APPEND VALUE #( %tky = ls-%tky CreatedOnDate = lv_today CreatedAtTime = lv_now ) TO lt_upd.
      ENDIF.
    ENDLOOP.
    MODIFY ENTITIES OF zi_gtpass IN LOCAL MODE
      ENTITY GatePass UPDATE FIELDS ( CreatedOnDate CreatedAtTime )
      WITH CORRESPONDING #( lt_upd ) REPORTED DATA(lt_rep).
  ENDMETHOD.
ENDCLASS.
