"! <p class="shorttext synchronized">Sales order release / order-reason update</p>
"! Clean-core successor to ZV2 (ZCBDC_SD_VA02_001), a VA02 BDC replay that, for each
"! input sales order (document category C), set the order reason (VBAK-AUGRU = '001')
"! and saved ("Update Status / Release SO"). This replaces the recorded screen replay
"! with BAPI_SALESORDER_CHANGE - no BDC.
"!
"! On-demand service: call release( ) with the sales-order list from a report or a
"! Fiori mass-action; runnable in ADT (F9) for testing.
CLASS zcl_so_release DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.

    TYPES tt_vbeln TYPE RANGE OF vbeln_va.
    TYPES tt_log   TYPE STANDARD TABLE OF string WITH EMPTY KEY.

    "! Set the order reason on the input sales orders (the ZV2 "release").
    "! @parameter it_vbeln  | sales-order selection (range)
    "! @parameter iv_reason | order reason to set (VBAK-AUGRU); default '001' as in ZV2
    "! @parameter iv_test   | true = simulate only (no BAPI change / commit)
    "! @parameter rt_log    | per-order result log
    METHODS release
      IMPORTING it_vbeln      TYPE tt_vbeln
                iv_reason     TYPE augru DEFAULT '001'
                iv_test       TYPE abap_bool DEFAULT abap_true
      RETURNING VALUE(rt_log) TYPE tt_log.
ENDCLASS.


CLASS zcl_so_release IMPLEMENTATION.

  METHOD release.
    " only genuine sales orders (document category C), as in ZV2
    SELECT vbeln FROM vbak
      WHERE vbeln IN @it_vbeln
        AND vbtyp = 'C'
      INTO TABLE @DATA(lt_order).

    IF lt_order IS INITIAL.
      APPEND |No sales orders (category C) match the selection| TO rt_log.
      RETURN.
    ENDIF.

    LOOP AT lt_order INTO DATA(ls_order).
      IF iv_test = abap_true.
        APPEND |SIMULATE release SO { ls_order-vbeln } (order reason { iv_reason })| TO rt_log.
        CONTINUE.
      ENDIF.

      DATA(ls_header)  = VALUE bapisdh1(  ord_reason = iv_reason ).
      DATA(ls_headerx) = VALUE bapisdh1x( updateflag = 'U' ord_reason = 'X' ).
      DATA lt_return TYPE STANDARD TABLE OF bapiret2.

      CALL FUNCTION 'BAPI_SALESORDER_CHANGE'
        EXPORTING  salesdocument    = ls_order-vbeln
                   order_header_in  = ls_header
                   order_header_inx = ls_headerx
        TABLES     return           = lt_return.

      IF line_exists( lt_return[ type = 'E' ] )
         OR line_exists( lt_return[ type = 'A' ] ).
        CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.
        LOOP AT lt_return INTO DATA(ls_ret) WHERE type CA 'EA'.
          APPEND |ERROR SO { ls_order-vbeln }: { ls_ret-message }| TO rt_log.
        ENDLOOP.
      ELSE.
        CALL FUNCTION 'BAPI_TRANSACTION_COMMIT' EXPORTING wait = abap_true.
        APPEND |RELEASED SO { ls_order-vbeln } (order reason { iv_reason })| TO rt_log.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.


  METHOD if_oo_adt_classrun~main.
    " Service class - call release( it_vbeln = ... ) from a report / Fiori mass-action.
    out->write( 'ZCL_SO_RELEASE: call release( it_vbeln = <sales order range> iv_test = abap_false ).' ).
    out->write( 'Sets VBAK-AUGRU (order reason) via BAPI_SALESORDER_CHANGE - the clean-core ZV2.' ).
  ENDMETHOD.

ENDCLASS.
