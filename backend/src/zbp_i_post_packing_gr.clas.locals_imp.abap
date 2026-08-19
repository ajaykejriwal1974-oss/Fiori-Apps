CLASS lhc_zi_post_packing_gr DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS postpackingandgr FOR MODIFY
      IMPORTING keys FOR ACTION PostPackGr~postPackingAndGr RESULT result.
ENDCLASS.

CLASS lhc_zi_post_packing_gr IMPLEMENTATION.
  METHOD postpackingandgr.
    DATA: ls_header TYPE bapi2017_gm_head_01,
          ls_code   TYPE bapi2017_gm_code,
          lt_item   TYPE STANDARD TABLE OF bapi2017_gm_item_create,
          ls_item   TYPE bapi2017_gm_item_create,
          lt_return TYPE STANDARD TABLE OF bapiret2,
          lv_matdoc TYPE bapi2017_gm_head_ret-mat_doc,
          lv_year   TYPE bapi2017_gm_head_ret-doc_year,
          lv_exidv  TYPE exidv,
          lv_rfcmsg TYPE c LENGTH 200.

    LOOP AT keys INTO DATA(ls_key).
      CLEAR: lt_item, lt_return, lv_matdoc, lv_year.
      SPLIT ls_key-%param-HandlingUnitList AT ';' INTO TABLE DATA(lt_hus).
      LOOP AT lt_hus INTO DATA(lv_hu).
        CONDENSE lv_hu.
        CHECK lv_hu IS NOT INITIAL.
        lv_exidv = |{ lv_hu ALPHA = IN }|.
        SELECT SINGLE venum FROM vekp WHERE exidv = @lv_exidv INTO @DATA(lv_venum).
        CHECK sy-subrc = 0.
        SELECT matnr, charg, vemng, vemeh FROM vepo
          WHERE venum = @lv_venum INTO TABLE @DATA(lt_vepo).
        LOOP AT lt_vepo INTO DATA(ls_vepo).
          CLEAR ls_item.
          ls_item-material_long = ls_vepo-matnr.
          ls_item-plant         = ls_key-%param-Plant.
          ls_item-stge_loc      = ls_key-%param-StorageLocation.
          ls_item-batch         = ls_vepo-charg.
          ls_item-move_type     = ls_key-%param-MovementType.
          ls_item-entry_qnt     = ls_vepo-vemng.
          ls_item-entry_uom     = ls_vepo-vemeh.
          APPEND ls_item TO lt_item.
        ENDLOOP.
      ENDLOOP.

      IF lt_item IS INITIAL.
        INSERT VALUE #( %cid = ls_key-%cid %param-message = |No HU contents found.| ) INTO TABLE result.
        CONTINUE.
      ENDIF.

      ls_header-pstng_date = sy-datum.
      ls_header-doc_date   = sy-datum.
      ls_code-gm_code      = COND #( WHEN ls_key-%param-MovementType(1) = '3' THEN '04'  " transfer
                                     ELSE '05' ).                                        " other receipt

      " BAPI_GOODSMVT_CREATE registers update-task work, which RAP forbids in the
      " interaction phase. Run it and its commit in a separate LUW via aRFC
      " (DESTINATION 'NONE'): the RAP transaction is untouched, the material
      " document posts, and the number is still returned to the caller.
      CALL FUNCTION 'BAPI_GOODSMVT_CREATE' DESTINATION 'NONE'
        EXPORTING  goodsmvt_header  = ls_header
                   goodsmvt_code    = ls_code
        IMPORTING  materialdocument = lv_matdoc
                   matdocumentyear  = lv_year
        TABLES     goodsmvt_item    = lt_item
                   return           = lt_return
        EXCEPTIONS system_failure        = 1 MESSAGE lv_rfcmsg
                   communication_failure = 2 MESSAGE lv_rfcmsg
                   OTHERS                = 3.
      IF sy-subrc <> 0.
        INSERT VALUE #( %cid = ls_key-%cid %param-message = |Posting failed: { lv_rfcmsg }| ) INTO TABLE result.
        CONTINUE.
      ENDIF.

      READ TABLE lt_return INTO DATA(ls_err) WITH KEY type = 'E'.
      IF sy-subrc = 0.
        CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK' DESTINATION 'NONE'
          EXCEPTIONS OTHERS = 0.
        INSERT VALUE #( %cid = ls_key-%cid %param-message = ls_err-message ) INTO TABLE result.
      ELSE.
        CALL FUNCTION 'BAPI_TRANSACTION_COMMIT' DESTINATION 'NONE'
          EXPORTING wait = 'X'
          EXCEPTIONS OTHERS = 0.
        INSERT VALUE #( %cid = ls_key-%cid
          %param-materialdocument = lv_matdoc
          %param-message = |Material document { lv_matdoc }/{ lv_year } posted.| ) INTO TABLE result.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.

CLASS lsc_zi_post_packing_gr DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PROTECTED SECTION.
    METHODS save REDEFINITION.
ENDCLASS.

CLASS lsc_zi_post_packing_gr IMPLEMENTATION.
  METHOD save.
  ENDMETHOD.
ENDCLASS.
