CLASS lhc_zi_hu_unpack DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS unpackitems FOR MODIFY
      IMPORTING keys FOR ACTION HuUnpack~unpackItems RESULT result.
ENDCLASS.

CLASS lhc_zi_hu_unpack IMPLEMENTATION.
  METHOD unpackitems.
    DATA: lv_msg    TYPE string,
          lv_exidv  TYPE exidv,
          lv_hukey  TYPE bapihukey-hu_exid,
          ls_item   TYPE bapihuitmunpack,
          lt_return TYPE STANDARD TABLE OF bapiret2,
          ls_return TYPE bapiret2.

    LOOP AT keys INTO DATA(ls_key).
      CLEAR lv_msg.
      SPLIT ls_key-%param-huitemlist AT ';' INTO TABLE DATA(lt_pairs).

      LOOP AT lt_pairs INTO DATA(lv_pair).
        CONDENSE lv_pair.
        IF lv_pair IS INITIAL.
          CONTINUE.
        ENDIF.
        SPLIT lv_pair AT '=' INTO DATA(lv_hu) DATA(lv_item).
        CONDENSE: lv_hu, lv_item.
        lv_exidv = |{ lv_hu ALPHA = IN }|.
        DATA(lv_vepos) = CONV vepos( lv_item ).

        SELECT SINGLE venum FROM vekp
          WHERE exidv = @lv_exidv INTO @DATA(lv_venum).
        IF sy-subrc <> 0.
          lv_msg = |{ lv_msg }{ lv_hu }: HU not found. |.
          CONTINUE.
        ENDIF.

        SELECT SINGLE vepos, matnr, charg, vemng, werks FROM vepo
          WHERE venum = @lv_venum AND vepos = @lv_vepos INTO @DATA(ls_vepo).
        IF sy-subrc <> 0.
          lv_msg = |{ lv_msg }{ lv_hu }/{ lv_item }: item not found. |.
          CONTINUE.
        ENDIF.

        lv_hukey = lv_exidv.
        CLEAR ls_item.
        ls_item-hu_item_type   = '1'.
        ls_item-hu_item_number = ls_vepo-vepos.
        ls_item-material       = ls_vepo-matnr.
        ls_item-batch          = ls_vepo-charg.
        ls_item-pack_qty       = ls_vepo-vemng.
        ls_item-plant          = ls_vepo-werks.

        CLEAR lt_return.
        CALL FUNCTION 'BAPI_HU_UNPACK'
          EXPORTING hukey = lv_hukey itemunpack = ls_item
          TABLES    return = lt_return.

        READ TABLE lt_return INTO ls_return WITH KEY type = 'E'.
        IF sy-subrc = 0.
          lv_msg = |{ lv_msg }{ lv_hu }/{ lv_item }: { ls_return-message }. |.
        ELSE.
          lv_msg = |{ lv_msg }{ lv_hu }/{ lv_item }: Handling Unit item emptied. |.
        ENDIF.
      ENDLOOP.

      IF lv_msg IS INITIAL.
        lv_msg = |No HU / item supplied.|.
      ENDIF.
      INSERT VALUE #( %cid = ls_key-%cid %param-message = lv_msg ) INTO TABLE result.
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.

CLASS lsc_zi_hu_unpack DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PROTECTED SECTION.
    METHODS save REDEFINITION.
ENDCLASS.

CLASS lsc_zi_hu_unpack IMPLEMENTATION.
  METHOD save.
  ENDMETHOD.
ENDCLASS.
