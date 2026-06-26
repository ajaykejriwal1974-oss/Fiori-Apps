*"* Unmanaged behavior for ZI_Contract_Item.
*"* updateBatches: change the batch on the given contract items in one call via
*"* the standard sales-document change API.

CLASS lhc_ContractItem DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS updateBatches FOR MODIFY
      IMPORTING keys FOR ACTION ContractItem~updateBatches RESULT result.
ENDCLASS.

CLASS lhc_ContractItem IMPLEMENTATION.

  METHOD updateBatches.
    LOOP AT keys INTO DATA(key).
      DATA(lv_contract) = key-%param-salescontract.
      DATA(lt_items)    = key-%param-_item.

      IF lv_contract IS INITIAL OR lt_items IS INITIAL.
        APPEND VALUE #( %cid = key-%cid
                        %param-message = 'No contract / items provided' ) TO result.
        CONTINUE.
      ENDIF.

      " Change the batch on each contract item via the sales-document change API.
      DATA lt_in  TYPE STANDARD TABLE OF bapisditm.
      DATA lt_inx TYPE STANDARD TABLE OF bapisditmx.
      lt_in  = VALUE #( FOR it IN lt_items ( itm_number = it-contractitem batch = it-newbatch ) ).
      lt_inx = VALUE #( FOR it IN lt_items ( itm_number = it-contractitem updateflag = 'U' batch = 'X' ) ).

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
                        %param = VALUE #( itemsupdated = lines( lt_items )
                                          message = |{ lines( lt_items ) } item(s) updated on contract { lv_contract }| ) ) TO result.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
