*"* Unmanaged behavior for ZI_MtosStock - the consolidated ZSOL_MTOS_PROCESS.
*"* convertToMts: post the special-stock conversion (sales-order stock -> own
*"*   stock) via BAPI_GOODSMVT_CREATE (e.g. movement type 411 E).
*"* createPhysInvDoc: create the physical-inventory document for the stock via
*"*   BAPI_MATPHYSINV_CREATE_MULT. No standard object is modified.

CLASS lhc_MtosStock DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS convertToMts    FOR MODIFY IMPORTING keys FOR ACTION MtosStock~convertToMts    RESULT result.
    METHODS createPhysInvDoc FOR MODIFY IMPORTING keys FOR ACTION MtosStock~createPhysInvDoc RESULT result.
ENDCLASS.

CLASS lhc_MtosStock IMPLEMENTATION.

  METHOD convertToMts.
    LOOP AT keys INTO DATA(key).
      DATA(ls_param) = key-%param.
      " TODO: post the special-stock conversion (sales-order stock -> own stock,
      "   e.g. movement type 411 E) via BAPI_GOODSMVT_CREATE.
      APPEND VALUE #( %cid = key-%cid
                      %param = VALUE #( message = 'TODO: wire BAPI_GOODSMVT_CREATE' ) ) TO result.
    ENDLOOP.
  ENDMETHOD.

  METHOD createPhysInvDoc.
    LOOP AT keys INTO DATA(key).
      DATA(ls_param) = key-%param.
      " TODO: create the physical-inventory document for the stock via
      "   BAPI_MATPHYSINV_CREATE_MULT.
      APPEND VALUE #( %cid = key-%cid
                      %param = VALUE #( message = 'TODO: wire BAPI_MATPHYSINV_CREATE_MULT' ) ) TO result.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
