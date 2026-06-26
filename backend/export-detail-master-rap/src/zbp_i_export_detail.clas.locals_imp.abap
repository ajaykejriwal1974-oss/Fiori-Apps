CLASS lhc_ExportDetail DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS validateKey FOR VALIDATE ON SAVE
      IMPORTING keys FOR ExportDetail~validateKey.
    METHODS validateExportCurrency FOR VALIDATE ON SAVE
      IMPORTING keys FOR ExportDetail~validateExportCurrency.
ENDCLASS.

CLASS lhc_ExportDetail IMPLEMENTATION.

  METHOD validateKey.
    READ ENTITIES OF zi_export_detail IN LOCAL MODE
      ENTITY ExportDetail FIELDS ( BillingDocument ) WITH CORRESPONDING #( keys )
      RESULT DATA(rows).
    LOOP AT rows INTO DATA(row).
      IF row-BillingDocument IS INITIAL.
        APPEND VALUE #( %tky = row-%tky ) TO failed-exportdetail.
        APPEND VALUE #( %tky = row-%tky
                        %msg = new_message_with_text(
                                 severity = if_abap_behv_message=>severity-error
                                 text     = 'BillingDocument is required' )
                        %element-BillingDocument = if_abap_behv=>mk-on ) TO reported-exportdetail.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD validateExportCurrency.
    READ ENTITIES OF zi_export_detail IN LOCAL MODE
      ENTITY ExportDetail FIELDS ( NetValue Currency ) WITH CORRESPONDING #( keys )
      RESULT DATA(rows).
    LOOP AT rows INTO DATA(row).
      IF row-NetValue IS NOT INITIAL AND row-Currency IS INITIAL.
        APPEND VALUE #( %tky = row-%tky ) TO failed-exportdetail.
        APPEND VALUE #( %tky = row-%tky
                        %msg = new_message_with_text(
                                 severity = if_abap_behv_message=>severity-error
                                 text     = 'Currency is required when a net value is entered' )
                        %element-Currency = if_abap_behv=>mk-on ) TO reported-exportdetail.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
