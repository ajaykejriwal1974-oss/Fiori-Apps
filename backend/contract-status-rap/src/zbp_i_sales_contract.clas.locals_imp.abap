*"* Unmanaged behavior for ZI_SalesContract - custom contract lifecycle.
*"* Each action drives the STANDARD sales document (BAPI_SD_SALESDOCUMENT_CHANGE
*"* / status management); no standard object is modified and nothing custom is
*"* persisted. Replaces ZCON_CLOSE / ZCON_CLOSE1 / ZCOREL / ZCON02.

CLASS lhc_SalesContract DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS closeContract     FOR MODIFY IMPORTING keys FOR ACTION SalesContract~closeContract     RESULT result.
    METHODS completeContract  FOR MODIFY IMPORTING keys FOR ACTION SalesContract~completeContract  RESULT result.
    METHODS releaseContract   FOR MODIFY IMPORTING keys FOR ACTION SalesContract~releaseContract   RESULT result.
    METHODS updatePendingRate FOR MODIFY IMPORTING keys FOR ACTION SalesContract~updatePendingRate RESULT result.
ENDCLASS.

CLASS lhc_SalesContract IMPLEMENTATION.

  METHOD closeContract.
    LOOP AT keys INTO DATA(key).
      DATA(p) = key-%param.
      " TODO: reject open items of contract p-SalesContract (set ABGRU / closed
      "   status) via BAPI_SD_SALESDOCUMENT_CHANGE; COMMIT on success.
      APPEND VALUE #( %cid = key-%cid
                      %param = VALUE #( salescontract = p-SalesContract
                                        message = 'TODO: wire ZSOL_CONTRACT_CLOSE (reject open qty)' ) ) TO result.
    ENDLOOP.
  ENDMETHOD.

  METHOD completeContract.
    LOOP AT keys INTO DATA(key).
      DATA(p) = key-%param.
      " TODO: close a fully-delivered contract (ZCON_CLOSE1) - mark complete only
      "   when delivery/billing status is C; else raise a message.
      APPEND VALUE #( %cid = key-%cid
                      %param = VALUE #( salescontract = p-SalesContract
                                        message = 'TODO: wire ZSOL_CONTRACT_CLOSE_ONE (completed close)' ) ) TO result.
    ENDLOOP.
  ENDMETHOD.

  METHOD releaseContract.
    LOOP AT keys INTO DATA(key).
      DATA(p) = key-%param.
      " TODO: remove delivery / billing block (release) via
      "   BAPI_SD_SALESDOCUMENT_CHANGE (clear LIFSK / FAKSK); COMMIT on success.
      APPEND VALUE #( %cid = key-%cid
                      %param = VALUE #( salescontract = p-SalesContract
                                        message = 'TODO: wire ZSOL_CONTRACT_RELEASE (remove block)' ) ) TO result.
    ENDLOOP.
  ENDMETHOD.

  METHOD updatePendingRate.
    LOOP AT keys INTO DATA(key).
      DATA(p) = key-%param.
      " TODO: update net price (KBETR of the price condition) on the open items
      "   of contract p-SalesContract to p-NewRate via BAPI_SD_SALESDOCUMENT_CHANGE
      "   (conditions table); restrict to pending items when SalesContractItem = 0.
      APPEND VALUE #( %cid = key-%cid
                      %param = VALUE #( salescontract = p-SalesContract
                                        message = 'TODO: wire ZSD_RPT_PCONTRACT_REG_PCON (rate update)' ) ) TO result.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
