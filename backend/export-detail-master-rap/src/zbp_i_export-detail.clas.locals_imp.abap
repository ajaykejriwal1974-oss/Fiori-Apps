CLASS lhc_ExportDetail DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS setDefaults FOR DETERMINE ON MODIFY
      IMPORTING keys FOR ExportDetail~setDefaults.
    METHODS validateKey FOR VALIDATE ON SAVE
      IMPORTING keys FOR ExportDetail~validateKey.
ENDCLASS.

CLASS lhc_ExportDetail IMPLEMENTATION.

  METHOD setDefaults.
    READ ENTITIES OF zi_export-detail IN LOCAL MODE
      ENTITY ExportDetail FIELDS ( IsActive ) WITH CORRESPONDING #( keys )
      RESULT DATA(rows).
    MODIFY ENTITIES OF zi_export-detail IN LOCAL MODE
      ENTITY ExportDetail UPDATE FIELDS ( IsActive )
        WITH VALUE #( FOR r IN rows (
          %tky     = r-%tky
          IsActive = COND #( WHEN r-IsActive IS INITIAL THEN abap_true ELSE r-IsActive ) ) )
      REPORTED DATA(upd).
  ENDMETHOD.

  METHOD validateKey.
    READ ENTITIES OF zi_export-detail IN LOCAL MODE
      ENTITY ExportDetail FIELDS ( ExportId ) WITH CORRESPONDING #( keys )
      RESULT DATA(rows).
    LOOP AT rows INTO DATA(row).
      IF row-ExportId IS INITIAL.
        APPEND VALUE #( %tky = row-%tky ) TO failed-exportdetail.
        APPEND VALUE #( %tky = row-%tky
                        %msg = new_message_with_text(
                                 severity = if_abap_behv_message=>severity-error
                                 text     = 'ExportId is required' )
                        %element-ExportId = if_abap_behv=>mk-on ) TO reported-exportdetail.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
