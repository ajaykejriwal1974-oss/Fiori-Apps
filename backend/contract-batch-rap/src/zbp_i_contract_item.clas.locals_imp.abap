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

      " TODO: change the batch on each item via the sales-document change API.
      "   order_header_inx = VALUE #( updateflag = 'U' )
      "   item    = VALUE #( FOR it IN lt_items ( itm_number = it-contractitem batch = it-newbatch ) )
      "   item_inx = VALUE #( FOR it IN lt_items ( itm_number = it-contractitem updateflag = 'U' batch = 'X' ) )
      "   CALL FUNCTION 'BAPI_SALESDOCUMENT_CHANGE'
      "     EXPORTING salesdocument = lv_contract ...
      "   (BAPI_SALESORDER_CHANGE / contract-specific BAPI per release)
      "   route return into reported/failed; commit on success.

      APPEND VALUE #( %cid  = key-%cid
                      %param = VALUE #( itemsupdated = lines( lt_items )
                                        message      = 'TODO: wire BAPI_SALESDOCUMENT_CHANGE' ) )
             TO result.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
