CLASS lhc_returnbox DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS unassign FOR MODIFY IMPORTING keys FOR ACTION ReturnBox~unassign.
ENDCLASS.
CLASS lhc_returnbox IMPLEMENTATION.
  METHOD unassign.
    LOOP AT keys INTO DATA(ls_key).
      UPDATE zpp_pack SET vbeln = @space, posnr = @space, pklst = @space
        WHERE boxno = @ls_key-BoxNo.
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.
