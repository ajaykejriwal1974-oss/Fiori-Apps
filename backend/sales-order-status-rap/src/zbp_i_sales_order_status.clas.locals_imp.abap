*"* Unmanaged behavior for ZI_SalesOrderStatus - sales order close.
*"* Each action drives the STANDARD sales document (BAPI_SD_SALESDOCUMENT_CHANGE).
*"* No standard object is modified and nothing custom is persisted.
*"* Replaces ZSOCLOSE (ZSOL_SALESORDER_CLOSE) / ZSOCLOSE1 (ZSOL_SO_CLOSE).

CLASS lhc_SalesOrder DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS closeSalesOrder   FOR MODIFY IMPORTING keys FOR ACTION SalesOrder~closeSalesOrder   RESULT result.
    METHODS closeOrderProgram FOR MODIFY IMPORTING keys FOR ACTION SalesOrder~closeOrderProgram RESULT result.
ENDCLASS.

CLASS lhc_SalesOrder IMPLEMENTATION.

  METHOD closeSalesOrder.
    LOOP AT keys INTO DATA(key).
      DATA(p) = key-%param.
      " TODO: reject open items of order p-SalesOrder (set ABGRU / closed status)
      "   via BAPI_SD_SALESDOCUMENT_CHANGE; COMMIT on success.
      APPEND VALUE #( %cid = key-%cid
                      %param = VALUE #( salesorder = p-SalesOrder
                                        message = 'TODO: wire ZSOL_SALESORDER_CLOSE (reject open qty)' ) ) TO result.
    ENDLOOP.
  ENDMETHOD.

  METHOD closeOrderProgram.
    LOOP AT keys INTO DATA(key).
      DATA(p) = key-%param.
      " TODO: mass-close variant (ZSOL_SO_CLOSE) - same per-order logic, applied
      "   over a selection; reuse closeSalesOrder per order.
      APPEND VALUE #( %cid = key-%cid
                      %param = VALUE #( salesorder = p-SalesOrder
                                        message = 'TODO: wire ZSOL_SO_CLOSE (mass close)' ) ) TO result.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
