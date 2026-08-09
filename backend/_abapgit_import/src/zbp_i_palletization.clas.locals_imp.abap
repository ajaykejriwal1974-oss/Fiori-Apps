CLASS lhc_zi_palletization DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS packpallet FOR MODIFY
      IMPORTING keys FOR ACTION Pallet~packPallet RESULT result.
ENDCLASS.

CLASS lhc_zi_palletization IMPLEMENTATION.
  METHOD packpallet.
    DATA: ls_hdrprop  TYPE bapihuhdrproposal,
          ls_huheader TYPE bapihuheader,
          lv_hukey    TYPE bapihukey-hu_exid,
          ls_itemprop TYPE bapihuitmproposal,
          lt_return   TYPE STANDARD TABLE OF bapiret2,
          lv_exidv    TYPE exidv,
          lv_count    TYPE i.

    LOOP AT keys INTO DATA(ls_key).
      CLEAR: ls_hdrprop, ls_huheader, lv_hukey, lt_return, lv_count.

      ls_hdrprop-pack_mat = ls_key-%param-PalletPackagingMaterial.
      ls_hdrprop-content  = ls_key-%param-Reference.

      CALL FUNCTION 'BAPI_HU_CREATE'
        EXPORTING headerproposal = ls_hdrprop
        IMPORTING huheader       = ls_huheader
                  hukey          = lv_hukey
        TABLES    return         = lt_return.

      READ TABLE lt_return INTO DATA(ls_err) WITH KEY type = 'E'.
      IF sy-subrc = 0.
        INSERT VALUE #( %cid = ls_key-%cid %param-message = ls_err-message ) INTO TABLE result.
        CONTINUE.
      ENDIF.

      SPLIT ls_key-%param-BoxHuList AT ';' INTO TABLE DATA(lt_boxes).
      LOOP AT lt_boxes INTO DATA(lv_box).
        CONDENSE lv_box.
        CHECK lv_box IS NOT INITIAL.
        lv_exidv = |{ lv_box ALPHA = IN }|.
        CLEAR: ls_itemprop, lt_return.
        ls_itemprop-hu_item_type     = '3'.          " handling unit
        ls_itemprop-lower_level_exid = lv_exidv.
        CALL FUNCTION 'BAPI_HU_PACK'
          EXPORTING hukey        = lv_hukey
                    itemproposal = ls_itemprop
          TABLES    return       = lt_return.
        READ TABLE lt_return TRANSPORTING NO FIELDS WITH KEY type = 'E'.
        IF sy-subrc <> 0.
          lv_count = lv_count + 1.
        ENDIF.
      ENDLOOP.

      INSERT VALUE #( %cid = ls_key-%cid
        %param-pallet      = lv_hukey
        %param-boxespacked = lv_count
        %param-message     = |Pallet { lv_hukey } created, { lv_count } box(es) packed.| ) INTO TABLE result.
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.

CLASS lsc_zi_palletization DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PROTECTED SECTION.
    METHODS save REDEFINITION.
ENDCLASS.

CLASS lsc_zi_palletization IMPLEMENTATION.
  METHOD save.
  ENDMETHOD.
ENDCLASS.
