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
      DATA(p) = key-%param.

      DATA(lv_today) = cl_abap_context_info=>get_system_date( ).
      DATA(ls_gm_header) = VALUE bapi2017_gm_head_01(
                             pstng_date = lv_today doc_date = lv_today pr_uname = sy-uname ).
      DATA(ls_gm_code) = VALUE bapi2017_gm_code( gm_code = '04' )." transfer posting

      " Movement type 411 E: transfer sales-order (special stock 'E') to own stock.
      DATA lt_gm_item TYPE STANDARD TABLE OF bapi2017_gm_item_create.
      lt_gm_item = VALUE #( ( material       = p-material
                              plant          = p-plant
                              move_type      = '411'
                              spec_stock     = 'E'
                              val_sales_ord  = p-salesorder
                              val_s_ord_item = p-salesorderitem
                              entry_qnt      = p-quantity
                              entry_uom      = p-baseunit ) ).

      DATA: lv_matdoc  TYPE bapi2017_gm_head_ret-mat_doc,
            lv_matyear TYPE bapi2017_gm_head_ret-doc_year.
      DATA lt_return TYPE STANDARD TABLE OF bapiret2.

      CALL FUNCTION 'BAPI_GOODSMVT_CREATE'
        EXPORTING goodsmvt_header  = ls_gm_header
                  goodsmvt_code    = ls_gm_code
        IMPORTING materialdocument = lv_matdoc
                  matdocumentyear  = lv_matyear
        TABLES    goodsmvt_item    = lt_gm_item
                  return           = lt_return.

      DATA(lv_errors) = REDUCE string( INIT s = ``
                          FOR r IN lt_return WHERE ( type = 'E' OR type = 'A' )
                          NEXT s = s && r-message && ` ` ).

      IF lv_errors IS NOT INITIAL.
        CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.
        APPEND VALUE #( %cid = key-%cid %param = VALUE #( message = lv_errors ) ) TO result.
      ELSE.
        CALL FUNCTION 'BAPI_TRANSACTION_COMMIT' EXPORTING wait = abap_true.
        APPEND VALUE #( %cid = key-%cid
                        %param = VALUE #( materialdocument = lv_matdoc
                                          message = |MTO->MTS posted: material document { lv_matdoc }| ) ) TO result.
      ENDIF.
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
