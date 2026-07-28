CLASS lcl_buffer DEFINITION.
  PUBLIC SECTION.
    TYPES: BEGIN OF ty_row,
             insplot    TYPE qals-prueflos,
             inspchar   TYPE qamv-merknr,
             mean_value TYPE bapi2045d2-mean_value,
             evaluation TYPE bapi2045d2-evaluation,
           END OF ty_row.
    CLASS-DATA gt_buffer TYPE STANDARD TABLE OF ty_row WITH EMPTY KEY.
ENDCLASS.

CLASS lhc_zi_qm_inspectionchar DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS update FOR MODIFY
      IMPORTING entities FOR UPDATE InspectionChar.
ENDCLASS.

CLASS lhc_zi_qm_inspectionchar IMPLEMENTATION.
  METHOD update.
    LOOP AT entities INTO DATA(ls_ent).
      APPEND VALUE #(
        insplot    = ls_ent-InspectionLot
        inspchar   = ls_ent-InspectionCharacteristic
        mean_value = ls_ent-ResultValue
        evaluation = ls_ent-Valuation ) TO lcl_buffer=>gt_buffer.
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.

CLASS lsc_zi_qm_inspectionchar DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PROTECTED SECTION.
    METHODS save REDEFINITION.
ENDCLASS.

CLASS lsc_zi_qm_inspectionchar IMPLEMENTATION.
  METHOD save.
    DATA: lt_char   TYPE STANDARD TABLE OF bapi2045d2,
          lt_sample TYPE STANDARD TABLE OF bapi2045d3,
          lt_single TYPE STANDARD TABLE OF bapi2045d4,
          lt_rettab TYPE STANDARD TABLE OF bapiret2,
          ls_return TYPE bapiret2.

    LOOP AT lcl_buffer=>gt_buffer INTO DATA(ls_row).
      CLEAR: lt_char, lt_sample, lt_single, lt_rettab, ls_return.
      APPEND VALUE #(
        insplot    = ls_row-insplot
        inspoper   = '0010'
        inspchar   = ls_row-inspchar
        mean_value = ls_row-mean_value
        evaluation = ls_row-evaluation
        closed     = 'X' ) TO lt_char.

      CALL FUNCTION 'BAPI_INSPOPER_RECORDRESULTS'
        EXPORTING  insplot        = ls_row-insplot
                   inspoper       = '0010'
        IMPORTING  return         = ls_return
        TABLES     char_results   = lt_char
                   sample_results = lt_sample
                   single_results = lt_single
                   returntable    = lt_rettab.
    ENDLOOP.
    CLEAR lcl_buffer=>gt_buffer.
  ENDMETHOD.
ENDCLASS.
