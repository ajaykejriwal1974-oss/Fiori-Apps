CLASS lhc_zi_packing_unit DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS createhandlingunits FOR MODIFY
      IMPORTING keys FOR ACTION PackingUnit~createHandlingUnits RESULT result.
ENDCLASS.

CLASS lhc_zi_packing_unit IMPLEMENTATION.
  METHOD createhandlingunits.
    DATA: ls_hdrprop  TYPE bapihuhdrproposal,
          ls_huheader TYPE bapihuheader,
          lv_hukey    TYPE bapihukey-hu_exid,
          lv_prev     TYPE bapihukey-hu_exid,
          ls_itemprop TYPE bapihuitmproposal,
          lt_return   TYPE STANDARD TABLE OF bapiret2,
          lv_meins    TYPE meins,
          lv_idx      TYPE i,
          lv_failed   TYPE abap_bool.

    LOOP AT keys INTO DATA(ls_key).
      CLEAR: lv_prev, lv_hukey, lv_idx, lv_failed.
      SELECT SINGLE meins FROM mara
        WHERE matnr = @ls_key-%param-Material INTO @lv_meins.

      SPLIT ls_key-%param-UnitList AT ';' INTO TABLE DATA(lt_levels).
      LOOP AT lt_levels INTO DATA(lv_level).
        CONDENSE lv_level.
        CHECK lv_level IS NOT INITIAL.
        lv_idx = lv_idx + 1.
        SPLIT lv_level AT '=' INTO DATA(lv_packmat) DATA(lv_qty).

        " --- create this level's HU ---
        CLEAR: ls_hdrprop, ls_huheader, lv_hukey, lt_return.
        ls_hdrprop-pack_mat = lv_packmat.
        ls_hdrprop-content  = |{ ls_key-%param-Reference } { ls_key-%param-Shade }|.
        CALL FUNCTION 'BAPI_HU_CREATE'
          EXPORTING headerproposal = ls_hdrprop
          IMPORTING huheader       = ls_huheader
                    hukey          = lv_hukey
          TABLES    return         = lt_return.
        READ TABLE lt_return INTO DATA(ls_cerr) WITH KEY type = 'E'.
        IF sy-subrc = 0.
          INSERT VALUE #( %cid = ls_key-%cid %param-message = ls_cerr-message ) INTO TABLE result.
          lv_failed = abap_true.
          EXIT.
        ENDIF.

        " --- pack into this HU ---
        CLEAR: ls_itemprop, lt_return.
        IF lv_idx = 1.
          ls_itemprop-hu_item_type  = '1'.                 " bottom: the material/batch
          ls_itemprop-material_long = ls_key-%param-Material.
          ls_itemprop-batch         = ls_key-%param-Batch.
          ls_itemprop-pack_qty      = lv_qty.
          ls_itemprop-base_unit_qty = lv_meins.
        ELSE.
          ls_itemprop-hu_item_type     = '3'.              " higher: the HU below
          ls_itemprop-lower_level_exid = lv_prev.
        ENDIF.
        CALL FUNCTION 'BAPI_HU_PACK'
          EXPORTING hukey        = lv_hukey
                    itemproposal = ls_itemprop
          TABLES    return       = lt_return.

        lv_prev = lv_hukey.
      ENDLOOP.

      IF lv_failed = abap_false AND lv_hukey IS NOT INITIAL.
        INSERT VALUE #( %cid = ls_key-%cid
          %param-handlingunit = lv_hukey
          %param-message      = |Top HU { lv_hukey } created ({ lv_idx } level(s)).| ) INTO TABLE result.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.

CLASS lsc_zi_packing_unit DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PROTECTED SECTION.
    METHODS save REDEFINITION.
ENDCLASS.

CLASS lsc_zi_packing_unit IMPLEMENTATION.
  METHOD save.
  ENDMETHOD.
ENDCLASS.
