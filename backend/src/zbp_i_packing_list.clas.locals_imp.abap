CLASS lhc_packing_list DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS createPackingList FOR MODIFY
      IMPORTING keys FOR ACTION PackingList~createPackingList RESULT result.
    METHODS changePackingList FOR MODIFY
      IMPORTING keys FOR ACTION PackingList~changePackingList RESULT result.
    METHODS deletePackingList FOR MODIFY
      IMPORTING keys FOR ACTION PackingList~deletePackingList RESULT result.
ENDCLASS.

CLASS lhc_packing_list IMPLEMENTATION.

  METHOD createPackingList.
    LOOP AT keys INTO DATA(key).
      UPDATE zpp_pack SET vbeln  = @key-%param-SalesOrder,
                          posnr  = @key-%param-SalesOrderItem,
                          pklst  = @key-%param-PackListItem,
                          pldate = @sy-datum
        WHERE boxno = @key-BoxNumber AND gjahr = @key-BoxYear.
      APPEND VALUE #( %tky-BoxNumber = key-BoxNumber
                      %tky-BoxYear   = key-BoxYear
                      %param = VALUE #( BoxesAffected = COND #( WHEN sy-subrc = 0 THEN 1 ELSE 0 )
                                        PackListItem  = key-%param-PackListItem
                                        Message = COND #( WHEN sy-subrc = 0
                                          THEN |Box { key-BoxNumber }/{ key-BoxYear } assigned to pack list { key-%param-PackListItem }.|
                                          ELSE |Box { key-BoxNumber }/{ key-BoxYear } not found.| ) ) )
             TO result.
    ENDLOOP.
  ENDMETHOD.

  METHOD changePackingList.
    LOOP AT keys INTO DATA(key).
      UPDATE zpp_pack SET vbeln  = @key-%param-SalesOrder,
                          posnr  = @key-%param-SalesOrderItem,
                          pklst  = @key-%param-PackListItem,
                          pldate = @sy-datum
        WHERE boxno = @key-BoxNumber AND gjahr = @key-BoxYear.
      APPEND VALUE #( %tky-BoxNumber = key-BoxNumber
                      %tky-BoxYear   = key-BoxYear
                      %param = VALUE #( BoxesAffected = COND #( WHEN sy-subrc = 0 THEN 1 ELSE 0 )
                                        PackListItem  = key-%param-PackListItem
                                        Message = COND #( WHEN sy-subrc = 0
                                          THEN |Box { key-BoxNumber }/{ key-BoxYear } re-assigned to pack list { key-%param-PackListItem }.|
                                          ELSE |Box { key-BoxNumber }/{ key-BoxYear } not found.| ) ) )
             TO result.
    ENDLOOP.
  ENDMETHOD.

  METHOD deletePackingList.
    LOOP AT keys INTO DATA(key).
      SELECT SINGLE boxno, gjahr, vbeln, posnr, pklst
        FROM zpp_pack
        WHERE boxno = @key-BoxNumber AND gjahr = @key-BoxYear
        INTO @DATA(ls_cur).
      IF sy-subrc = 0 AND ls_cur-pklst IS NOT INITIAL.
        INSERT zplistd FROM @( VALUE zplistd( vbeln = ls_cur-vbeln
                                              posnr = ls_cur-posnr
                                              pklst = ls_cur-pklst
                                              boxno = ls_cur-boxno ) ).
      ENDIF.
      UPDATE zpp_pack SET vbeln  = @space,
                          posnr  = @space,
                          pklst  = @space,
                          pldate = '00000000'
        WHERE boxno = @key-BoxNumber AND gjahr = @key-BoxYear.
      APPEND VALUE #( %tky-BoxNumber = key-BoxNumber
                      %tky-BoxYear   = key-BoxYear
                      %param = VALUE #( BoxesAffected = COND #( WHEN sy-subrc = 0 THEN 1 ELSE 0 )
                                        Message = |Box { key-BoxNumber }/{ key-BoxYear } removed from packing list.| ) )
             TO result.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
