CLASS lhc_zi_packing_detail DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS packitems FOR MODIFY
      IMPORTING keys FOR ACTION PackingItem~packItems RESULT result.
    METHODS repackitems FOR MODIFY
      IMPORTING keys FOR ACTION PackingItem~repackItems RESULT result.
ENDCLASS.

CLASS lhc_zi_packing_detail IMPLEMENTATION.

  METHOD packitems.
    DATA: ls_hdrprop  TYPE bapihuhdrproposal,
          ls_huheader TYPE bapihuheader,
          lv_hukey    TYPE bapihukey-hu_exid,
          ls_itemprop TYPE bapihuitmproposal,
          lt_return   TYPE STANDARD TABLE OF bapiret2,
          lv_msg      TYPE string.

    LOOP AT keys INTO DATA(ls_key).
      CLEAR: ls_hdrprop, ls_huheader, lv_hukey, lt_return, lv_msg.
      ls_hdrprop-pack_mat = ls_key-%param-PackagingMaterial.
      ls_hdrprop-content  = ls_key-%param-Reference.

      CALL FUNCTION 'BAPI_HU_CREATE'
        EXPORTING headerproposal = ls_hdrprop
        IMPORTING huheader       = ls_huheader
                  hukey          = lv_hukey
        TABLES    return         = lt_return.

      READ TABLE lt_return INTO DATA(ls_cerr) WITH KEY type = 'E'.
      IF sy-subrc = 0.
        INSERT VALUE #( %cid = ls_key-%cid %param-message = ls_cerr-message ) INTO TABLE result.
        CONTINUE.
      ENDIF.

      SPLIT ls_key-%param-ItemList AT ';' INTO TABLE DATA(lt_items).
      LOOP AT lt_items INTO DATA(lv_row).
        CONDENSE lv_row.
        CHECK lv_row IS NOT INITIAL.
        SPLIT lv_row AT '=' INTO DATA(lv_mat) DATA(lv_batch) DATA(lv_qty) DATA(lv_unit).
        CLEAR: ls_itemprop, lt_return.
        ls_itemprop-hu_item_type  = '1'.
        ls_itemprop-material_long = lv_mat.
        ls_itemprop-batch         = lv_batch.
        ls_itemprop-pack_qty      = lv_qty.
        ls_itemprop-base_unit_qty = lv_unit.
        CALL FUNCTION 'BAPI_HU_PACK'
          EXPORTING hukey        = lv_hukey
                    itemproposal = ls_itemprop
          TABLES    return       = lt_return.
        READ TABLE lt_return INTO DATA(ls_ierr) WITH KEY type = 'E'.
        IF sy-subrc = 0.
          lv_msg = |{ lv_msg } { ls_ierr-message }|.
        ENDIF.
      ENDLOOP.

      INSERT VALUE #( %cid = ls_key-%cid
        %param-handlingunit = lv_hukey
        %param-message      = COND #( WHEN lv_msg IS INITIAL
                                      THEN |HU { lv_hukey } created and packed.|
                                      ELSE |HU { lv_hukey } created.{ lv_msg }| ) ) INTO TABLE result.
    ENDLOOP.
  ENDMETHOD.

  METHOD repackitems.
    DATA: lt_repack TYPE STANDARD TABLE OF bapihurepack,
          ls_repack TYPE bapihurepack,
          lt_desthu TYPE STANDARD TABLE OF bapihunumber,
          lt_return TYPE STANDARD TABLE OF bapiret2,
          lv_source TYPE exidv,
          lv_target TYPE exidv,
          lv_vepos  TYPE vepos.

    LOOP AT keys INTO DATA(ls_key).
      CLEAR: lt_repack, lt_desthu, lt_return.
      lv_source = |{ ls_key-%param-SourceHandlingUnit ALPHA = IN }|.
      lv_target = |{ ls_key-%param-TargetHandlingUnit ALPHA = IN }|.

      SELECT SINGLE venum FROM vekp WHERE exidv = @lv_source INTO @DATA(lv_venum).
      IF sy-subrc <> 0.
        INSERT VALUE #( %cid = ls_key-%cid
          %param-message = |Source HU { ls_key-%param-SourceHandlingUnit } not found.| ) INTO TABLE result.
        CONTINUE.
      ENDIF.

      lt_desthu = VALUE #( ( hu_exid = lv_target ) ).

      SPLIT ls_key-%param-ItemList AT ';' INTO TABLE DATA(lt_pairs).
      LOOP AT lt_pairs INTO DATA(lv_pair).
        CONDENSE lv_pair.
        CHECK lv_pair IS NOT INITIAL.
        SPLIT lv_pair AT '=' INTO DATA(lv_item) DATA(lv_qty).
        lv_vepos = |{ lv_item ALPHA = IN }|.
        SELECT SINGLE matnr, charg, vemeh FROM vepo
          WHERE venum = @lv_venum AND vepos = @lv_vepos INTO @DATA(ls_vepo).
        CHECK sy-subrc = 0.
        CLEAR ls_repack.
        ls_repack-source_hu     = lv_source.
        ls_repack-material_long = ls_vepo-matnr.
        ls_repack-batch         = ls_vepo-charg.
        ls_repack-pack_qty      = lv_qty.
        ls_repack-base_uom      = ls_vepo-vemeh.
        APPEND ls_repack TO lt_repack.
      ENDLOOP.

      IF lt_repack IS INITIAL.
        INSERT VALUE #( %cid = ls_key-%cid %param-message = |No valid items to repack.| ) INTO TABLE result.
        CONTINUE.
      ENDIF.

      CALL FUNCTION 'BAPI_HU_REPACK'
        EXPORTING hukey  = CONV bapihukey-hu_exid( lv_source )
        TABLES    repack = lt_repack
                  desthu = lt_desthu
                  return = lt_return.

      READ TABLE lt_return INTO DATA(ls_err) WITH KEY type = 'E'.
      IF sy-subrc = 0.
        IF ls_err-message IS INITIAL AND ls_err-id IS NOT INITIAL.
          MESSAGE ID ls_err-id TYPE 'E' NUMBER ls_err-number
            WITH ls_err-message_v1 ls_err-message_v2 ls_err-message_v3 ls_err-message_v4
            INTO ls_err-message.
        ENDIF.
        INSERT VALUE #( %cid = ls_key-%cid %param-message = ls_err-message ) INTO TABLE result.
      ELSE.
        INSERT VALUE #( %cid = ls_key-%cid
          %param-message = |Repacked to HU { ls_key-%param-TargetHandlingUnit }.| ) INTO TABLE result.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.

CLASS lsc_zi_packing_detail DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PROTECTED SECTION.
    METHODS save REDEFINITION.
ENDCLASS.

CLASS lsc_zi_packing_detail IMPLEMENTATION.
  METHOD save.
  ENDMETHOD.
ENDCLASS.
