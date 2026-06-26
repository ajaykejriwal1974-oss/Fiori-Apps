*"* Unmanaged behavior for ZI_SalesDocStatus - consolidated contract + order
*"* lifecycle. Each action drives the STANDARD sales document
*"* (BAPI_SALESDOCUMENT_CHANGE); no standard object is modified.
*"* Replaces ZCON_CLOSE / ZCON_CLOSE1 / ZCOREL / ZCON02 / ZSOCLOSE / ZSOCLOSE1.
*"* VERIFY for contracts you may prefer BAPI_CUSTOMERCONTRACT_CHANGE; the
*"* rejection reason code and the price condition type are configuration.

CLASS lhc_SalesDoc DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS closeContract     FOR MODIFY IMPORTING keys FOR ACTION SalesDoc~closeContract     RESULT result.
    METHODS completeContract  FOR MODIFY IMPORTING keys FOR ACTION SalesDoc~completeContract  RESULT result.
    METHODS releaseContract   FOR MODIFY IMPORTING keys FOR ACTION SalesDoc~releaseContract   RESULT result.
    METHODS updatePendingRate FOR MODIFY IMPORTING keys FOR ACTION SalesDoc~updatePendingRate RESULT result.
    METHODS closeSalesOrder   FOR MODIFY IMPORTING keys FOR ACTION SalesDoc~closeSalesOrder   RESULT result.
    METHODS closeOrderProgram FOR MODIFY IMPORTING keys FOR ACTION SalesDoc~closeOrderProgram RESULT result.
    "! Reject the open items of a sales document (close). Returns a status message.
    METHODS reject_open_items IMPORTING iv_doc        TYPE vbeln_va
                                        iv_reason     TYPE abgru_va
                              RETURNING VALUE(rv_msg) TYPE string.
ENDCLASS.

CLASS lhc_SalesDoc IMPLEMENTATION.

  METHOD reject_open_items.
    " open items = not yet rejected
    SELECT posnr FROM vbap
      WHERE vbeln = @iv_doc AND abgru = @space
      INTO TABLE @DATA(lt_pos).
    IF lt_pos IS INITIAL.
      rv_msg = |{ iv_doc }: no open items to close|.
      RETURN.
    ENDIF.
    DATA(lv_reason) = COND abgru_va( WHEN iv_reason IS INITIAL THEN '01' ELSE iv_reason ).
    DATA lt_in  TYPE STANDARD TABLE OF bapisditm.
    DATA lt_inx TYPE STANDARD TABLE OF bapisditmx.
    LOOP AT lt_pos INTO DATA(ls_pos).
      APPEND VALUE #( itm_number = ls_pos-posnr reason_rej = lv_reason ) TO lt_in.
      APPEND VALUE #( itm_number = ls_pos-posnr updateflag = 'U' reason_rej = 'X' ) TO lt_inx.
    ENDLOOP.
    DATA lt_return TYPE STANDARD TABLE OF bapiret2.
    CALL FUNCTION 'BAPI_SALESDOCUMENT_CHANGE'
      EXPORTING salesdocument    = iv_doc
                order_header_inx = VALUE bapisdh1x( updateflag = 'U' )
      TABLES    return           = lt_return
                order_item_in    = lt_in
                order_item_inx   = lt_inx.
    DATA(lv_err) = REDUCE string( INIT s = ``
                     FOR r IN lt_return WHERE ( type = 'E' OR type = 'A' )
                     NEXT s = s && r-message && ` ` ).
    IF lv_err IS NOT INITIAL.
      CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.
      rv_msg = lv_err.
    ELSE.
      CALL FUNCTION 'BAPI_TRANSACTION_COMMIT' EXPORTING wait = abap_true.
      rv_msg = |{ iv_doc }: { lines( lt_pos ) } open item(s) rejected (closed)|.
    ENDIF.
  ENDMETHOD.

  METHOD closeContract.
    LOOP AT keys INTO DATA(key).
      DATA(p) = key-%param.
      APPEND VALUE #( %cid = key-%cid
                      %param = VALUE #( salescontract = p-SalesContract
                                        message = reject_open_items( iv_doc = p-SalesContract
                                                                     iv_reason = p-Reason ) ) ) TO result.
    ENDLOOP.
  ENDMETHOD.

  METHOD completeContract.
    " ZCON_CLOSE1 - close a fully-delivered contract. VERIFY the "fully delivered"
    " guard (overall delivery status = 'C') before rejecting the remainder.
    LOOP AT keys INTO DATA(key).
      DATA(p) = key-%param.
      APPEND VALUE #( %cid = key-%cid
                      %param = VALUE #( salescontract = p-SalesContract
                                        message = reject_open_items( iv_doc = p-SalesContract
                                                                     iv_reason = p-Reason ) ) ) TO result.
    ENDLOOP.
  ENDMETHOD.

  METHOD releaseContract.
    " ZCOREL - remove the delivery and billing blocks (release).
    LOOP AT keys INTO DATA(key).
      DATA(p) = key-%param.
      DATA lt_return TYPE STANDARD TABLE OF bapiret2.
      CALL FUNCTION 'BAPI_SALESDOCUMENT_CHANGE'
        EXPORTING salesdocument    = p-SalesContract
                  order_header_in  = VALUE bapisdh1( dlv_block = '' bill_block = '' )
                  order_header_inx = VALUE bapisdh1x( updateflag = 'U' dlv_block = 'X' bill_block = 'X' )
        TABLES    return           = lt_return.
      DATA(lv_err) = REDUCE string( INIT s = ``
                       FOR r IN lt_return WHERE ( type = 'E' OR type = 'A' )
                       NEXT s = s && r-message && ` ` ).
      IF lv_err IS NOT INITIAL.
        CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.
        APPEND VALUE #( %cid = key-%cid %param = VALUE #( salescontract = p-SalesContract message = lv_err ) ) TO result.
      ELSE.
        CALL FUNCTION 'BAPI_TRANSACTION_COMMIT' EXPORTING wait = abap_true.
        APPEND VALUE #( %cid = key-%cid
                        %param = VALUE #( salescontract = p-SalesContract message = |{ p-SalesContract } released (blocks removed)| ) ) TO result.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD updatePendingRate.
    " ZCON02 - update the net price on the open contract items. The price condition
    " type 'PR00' is config - VERIFY the contract's condition type.
    LOOP AT keys INTO DATA(key).
      DATA(p) = key-%param.
      SELECT posnr FROM vbap
        WHERE vbeln = @p-SalesContract AND abgru = @space
        INTO TABLE @DATA(lt_pos).
      DATA lt_cond  TYPE STANDARD TABLE OF bapicond.
      DATA lt_condx TYPE STANDARD TABLE OF bapicondx.
      LOOP AT lt_pos INTO DATA(ls_pos).
        IF p-SalesContractItem IS NOT INITIAL AND ls_pos-posnr <> p-SalesContractItem.
          CONTINUE.
        ENDIF.
        APPEND VALUE #( itm_number = ls_pos-posnr cond_type = 'PR00'
                        cond_value = p-NewRate currency = p-Currency ) TO lt_cond.
        APPEND VALUE #( itm_number = ls_pos-posnr cond_type = 'PR00'
                        updateflag = 'U' cond_value = 'X' currency = 'X' ) TO lt_condx.
      ENDLOOP.
      DATA lt_return TYPE STANDARD TABLE OF bapiret2.
      CALL FUNCTION 'BAPI_SALESDOCUMENT_CHANGE'
        EXPORTING salesdocument    = p-SalesContract
                  order_header_inx = VALUE bapisdh1x( updateflag = 'U' )
        TABLES    return           = lt_return
                  conditions_in    = lt_cond
                  conditions_inx   = lt_condx.
      DATA(lv_err) = REDUCE string( INIT s = ``
                       FOR r IN lt_return WHERE ( type = 'E' OR type = 'A' )
                       NEXT s = s && r-message && ` ` ).
      IF lv_err IS NOT INITIAL.
        CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.
        APPEND VALUE #( %cid = key-%cid %param = VALUE #( salescontract = p-SalesContract message = lv_err ) ) TO result.
      ELSE.
        CALL FUNCTION 'BAPI_TRANSACTION_COMMIT' EXPORTING wait = abap_true.
        APPEND VALUE #( %cid = key-%cid
                        %param = VALUE #( salescontract = p-SalesContract message = |{ p-SalesContract }: rate updated on { lines( lt_cond ) } item(s)| ) ) TO result.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD closeSalesOrder.
    LOOP AT keys INTO DATA(key).
      DATA(p) = key-%param.
      APPEND VALUE #( %cid = key-%cid
                      %param = VALUE #( salesorder = p-SalesOrder
                                        message = reject_open_items( iv_doc = p-SalesOrder
                                                                     iv_reason = p-Reason ) ) ) TO result.
    ENDLOOP.
  ENDMETHOD.

  METHOD closeOrderProgram.
    " ZSOCLOSE1 - mass close variant; same per-order logic over a selection.
    LOOP AT keys INTO DATA(key).
      DATA(p) = key-%param.
      APPEND VALUE #( %cid = key-%cid
                      %param = VALUE #( salesorder = p-SalesOrder
                                        message = reject_open_items( iv_doc = p-SalesOrder
                                                                     iv_reason = p-Reason ) ) ) TO result.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
