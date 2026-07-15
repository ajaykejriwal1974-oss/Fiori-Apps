*"* Unmanaged behavior for ZI_CONTRACT_ITEM.
*"* updateBatches: change the batch on the given contract items in one call via
*"* the standard sales-document change API. The items travel in the flat
*"* ItemBatchList parameter as 'ITEM=BATCH;ITEM=BATCH' (e.g. '000010=B123').

CLASS lhc_ContractItem DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS updateBatches FOR MODIFY
      IMPORTING keys FOR ACTION ContractItem~updateBatches RESULT result.
ENDCLASS.

CLASS lhc_ContractItem IMPLEMENTATION.

  METHOD updateBatches.
    LOOP AT keys INTO DATA(key).
      DATA(lv_contract) = key-%param-salescontract.
      DATA(lv_list)     = key-%param-itembatchlist.

      DATA lt_in  TYPE STANDARD TABLE OF bapisditm.
      DATA lt_inx TYPE STANDARD TABLE OF bapisditmx.
      CLEAR: lt_in, lt_inx.
      SPLIT lv_list AT ';' INTO TABLE DATA(lt_tok).
      LOOP AT lt_tok INTO DATA(lv_tok).
        CONDENSE lv_tok NO-GAPS.
        IF lv_tok IS INITIAL. CONTINUE. ENDIF.
        SPLIT lv_tok AT '=' INTO DATA(lv_item) DATA(lv_batch).
        APPEND VALUE #( itm_number = lv_item batch = lv_batch ) TO lt_in.
        APPEND VALUE #( itm_number = lv_item updateflag = 'U' batch = 'X' ) TO lt_inx.
      ENDLOOP.

      IF lv_contract IS INITIAL OR lt_in IS INITIAL.
        APPEND VALUE #( %cid = key-%cid
                        %param-message = 'No contract / items provided' ) TO result.
        CONTINUE.
      ENDIF.

      DATA lt_return TYPE STANDARD TABLE OF bapiret2.
      CALL FUNCTION 'BAPI_SALESDOCUMENT_CHANGE'
        EXPORTING salesdocument    = lv_contract
                  order_header_inx = VALUE bapisdh1x( updateflag = 'U' )
        TABLES    return           = lt_return
                  order_item_in    = lt_in
                  order_item_inx   = lt_inx.

      DATA(lv_err) = REDUCE string( INIT s = ``
                       FOR r IN lt_return WHERE ( type = 'E' OR type = 'A' )
                       NEXT s = s && r-message && ` ` ).
      IF lv_err IS NOT INITIAL.
        CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.
        APPEND VALUE #( %cid = key-%cid %param = VALUE #( message = lv_err ) ) TO result.
      ELSE.
        CALL FUNCTION 'BAPI_TRANSACTION_COMMIT' EXPORTING wait = abap_true.
        APPEND VALUE #( %cid = key-%cid
                        %param = VALUE #( itemsupdated = lines( lt_in )
                                          message = |{ lines( lt_in ) } item(s) updated on contract { lv_contract }| ) ) TO result.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
