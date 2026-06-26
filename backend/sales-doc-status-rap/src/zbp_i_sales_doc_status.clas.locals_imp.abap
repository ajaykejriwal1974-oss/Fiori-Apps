*"* Unmanaged behavior for ZI_SalesDocStatus - consolidated contract + order
*"* lifecycle. Each action drives the STANDARD sales document
*"* (BAPI_SD_SALESDOCUMENT_CHANGE); no standard object is modified.
*"* Replaces ZCON_CLOSE / ZCON_CLOSE1 / ZCOREL / ZCON02 / ZSOCLOSE / ZSOCLOSE1.

CLASS lhc_SalesDoc DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS closeContract     FOR MODIFY IMPORTING keys FOR ACTION SalesDoc~closeContract     RESULT result.
    METHODS completeContract  FOR MODIFY IMPORTING keys FOR ACTION SalesDoc~completeContract  RESULT result.
    METHODS releaseContract   FOR MODIFY IMPORTING keys FOR ACTION SalesDoc~releaseContract   RESULT result.
    METHODS updatePendingRate FOR MODIFY IMPORTING keys FOR ACTION SalesDoc~updatePendingRate RESULT result.
    METHODS closeSalesOrder   FOR MODIFY IMPORTING keys FOR ACTION SalesDoc~closeSalesOrder   RESULT result.
    METHODS closeOrderProgram FOR MODIFY IMPORTING keys FOR ACTION SalesDoc~closeOrderProgram RESULT result.
ENDCLASS.

CLASS lhc_SalesDoc IMPLEMENTATION.

  METHOD closeContract.
    LOOP AT keys INTO DATA(key).
      DATA(p) = key-%param.
      " TODO: reject open items of contract p-SalesContract (ABGRU/closed status)
      "   via BAPI_SD_SALESDOCUMENT_CHANGE; COMMIT on success.
      APPEND VALUE #( %cid = key-%cid
                      %param = VALUE #( salescontract = p-SalesContract
                                        message = 'TODO: wire ZSOL_CONTRACT_CLOSE' ) ) TO result.
    ENDLOOP.
  ENDMETHOD.

  METHOD completeContract.
    LOOP AT keys INTO DATA(key).
      DATA(p) = key-%param.
      " TODO: close a fully-delivered contract (ZCON_CLOSE1).
      APPEND VALUE #( %cid = key-%cid
                      %param = VALUE #( salescontract = p-SalesContract
                                        message = 'TODO: wire ZSOL_CONTRACT_CLOSE_ONE' ) ) TO result.
    ENDLOOP.
  ENDMETHOD.

  METHOD releaseContract.
    LOOP AT keys INTO DATA(key).
      DATA(p) = key-%param.
      " TODO: remove delivery/billing block (clear LIFSK/FAKSK) via BAPI_SD_SALESDOCUMENT_CHANGE.
      APPEND VALUE #( %cid = key-%cid
                      %param = VALUE #( salescontract = p-SalesContract
                                        message = 'TODO: wire ZSOL_CONTRACT_RELEASE' ) ) TO result.
    ENDLOOP.
  ENDMETHOD.

  METHOD updatePendingRate.
    LOOP AT keys INTO DATA(key).
      DATA(p) = key-%param.
      " TODO: update net price (KBETR) on the open items of p-SalesContract to
      "   p-NewRate via BAPI_SD_SALESDOCUMENT_CHANGE (conditions).
      APPEND VALUE #( %cid = key-%cid
                      %param = VALUE #( salescontract = p-SalesContract
                                        message = 'TODO: wire ZSD_RPT_PCONTRACT_REG_PCON' ) ) TO result.
    ENDLOOP.
  ENDMETHOD.

  METHOD closeSalesOrder.
    LOOP AT keys INTO DATA(key).
      DATA(p) = key-%param.
      " TODO: reject open items of order p-SalesOrder via BAPI_SD_SALESDOCUMENT_CHANGE.
      APPEND VALUE #( %cid = key-%cid
                      %param = VALUE #( salesorder = p-SalesOrder
                                        message = 'TODO: wire ZSOL_SALESORDER_CLOSE' ) ) TO result.
    ENDLOOP.
  ENDMETHOD.

  METHOD closeOrderProgram.
    LOOP AT keys INTO DATA(key).
      DATA(p) = key-%param.
      " TODO: mass-close variant (ZSOL_SO_CLOSE) - same per-order logic over a selection.
      APPEND VALUE #( %cid = key-%cid
                      %param = VALUE #( salesorder = p-SalesOrder
                                        message = 'TODO: wire ZSOL_SO_CLOSE' ) ) TO result.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
