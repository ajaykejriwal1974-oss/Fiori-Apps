"! <p class="shorttext synchronized">PO creation automation (replaces ZAUTOPO*)</p>
"! Back-to-back PO automation, the clean-core successor to the nine ZAUTOPO*
"! plant clones (ZPRG_PO_CREATE*). Reads config from ZSOL_AUPO and the
"! billing items to process, creates the PO via the Purchase Order API, and
"! logs billing-item -> PO in ZMM_AUTOPO so nothing is reprocessed.
"!
"! Schedulable via Application Job Scheduling (no selection-screen report);
"! runnable in ADT (F9) via if_oo_adt_classrun for testing. Sales org is a
"! PARAMETER - the single class replaces all nine per-plant copies.
CLASS zcl_po_automation DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.        " run in ADT (console) for test
    INTERFACES if_apj_dt_exec_object.     " Application Job - design time (parameters)
    INTERFACES if_apj_rt_exec_object.     " Application Job - runtime (execute)

    TYPES tt_log TYPE STANDARD TABLE OF string WITH EMPTY KEY.

    "! Create back-to-back POs for one sales organization.
    "! @parameter iv_vkorg | sales organization (the consolidation parameter)
    "! @parameter iv_test  | true = simulate only (no PO, no ZMM_AUTOPO insert)
    "! @parameter rt_log   | per-item processing log
    METHODS run
      IMPORTING iv_vkorg      TYPE vkorg
                iv_test       TYPE abap_bool DEFAULT abap_true
      RETURNING VALUE(rt_log) TYPE tt_log.

  PRIVATE SECTION.
    CONSTANTS c_param_vkorg TYPE string VALUE 'VKORG' ##NO_TEXT.
ENDCLASS.


CLASS zcl_po_automation IMPLEMENTATION.

  METHOD run.
    " 1) PO-creation config for this sales org (purchasing org / PO type / vendor)
    SELECT SINGLE * FROM zsol_aupo
      WHERE vkorg = @iv_vkorg
      INTO @DATA(ls_cfg).
    IF sy-subrc <> 0.
      APPEND |No ZSOL_AUPO config for sales org { iv_vkorg }| TO rt_log.
      RETURN.
    ENDIF.

    " 2) billing items in this sales org not yet auto-processed (absent from ZMM_AUTOPO).
    "    Read the STANDARD billing tables (clean core) - the legacy ZKIL_VBRK log is
    "    not required once we key off ZMM_AUTOPO.
    SELECT k~vbeln, p~posnr, p~matnr, p~fkimg, p~meins, p~werks
      FROM vbrk AS k
      INNER JOIN vbrp AS p ON p~vbeln = k~vbeln
      WHERE k~vkorg = @iv_vkorg
        AND k~fksto = @abap_false                      " not cancelled
        AND NOT EXISTS ( SELECT 1 FROM zmm_autopo AS a
                           WHERE a~vbeln = p~vbeln
                             AND a~posnr = p~posnr )
      INTO TABLE @DATA(lt_items).

    IF lt_items IS INITIAL.
      APPEND |Sales org { iv_vkorg }: nothing to process| TO rt_log.
      RETURN.
    ENDIF.

    " 3) one PO per billing item (group as needed). API call marked TODO.
    LOOP AT lt_items INTO DATA(ls_item).
      DATA lv_ebeln TYPE ebeln.

      IF iv_test = abap_false.
        " TODO: create the PO via the Purchase Order API / BAPI_PO_CREATE1 using
        "   header  : comp.code ls_cfg-bukrs, purch.org ls_cfg-ekorg,
        "             purch.grp ls_cfg-ekgrp, doc type ls_cfg-bsart, vendor ls_cfg-lifnr
        "   item    : material ls_item-matnr, plant ls_item-werks,
        "             quantity ls_item-fkimg, unit ls_item-meins
        "   -> lv_ebeln = created PO number; BAPI_TRANSACTION_COMMIT on success.
        "
        " On success, log so the item is never reprocessed:
        "   INSERT zmm_autopo FROM @( VALUE #( vbeln = ls_item-vbeln
        "                                      posnr = ls_item-posnr
        "                                      ebeln = lv_ebeln ) ).
      ENDIF.

      APPEND |{ COND #( WHEN iv_test = abap_true THEN 'SIMULATE' ELSE 'CREATE' ) }| &&
             | PO for billing { ls_item-vbeln }/{ ls_item-posnr } | &&
             |mat { ls_item-matnr } qty { ls_item-fkimg } (vendor { ls_cfg-lifnr })| TO rt_log.
    ENDLOOP.
  ENDMETHOD.


  METHOD if_oo_adt_classrun~main.
    " Dev/test: simulate every configured sales org.
    SELECT DISTINCT vkorg FROM zsol_aupo INTO TABLE @DATA(lt_vkorg).
    IF lt_vkorg IS INITIAL.
      out->write( 'No ZSOL_AUPO configuration found.' ).
      RETURN.
    ENDIF.
    LOOP AT lt_vkorg INTO DATA(lv_vkorg).
      out->write( |== Sales org { lv_vkorg } (simulation) ==| ).
      DATA(lt_log) = run( iv_vkorg = lv_vkorg iv_test = abap_true ).
      LOOP AT lt_log INTO DATA(lv_line).
        out->write( lv_line ).
      ENDLOOP.
    ENDLOOP.
  ENDMETHOD.


  METHOD if_apj_rt_exec_object~execute.
    " Application Job runtime: read the VKORG parameter, run for real.
    DATA lv_vkorg TYPE vkorg.
    LOOP AT it_parameters INTO DATA(ls_param).
      IF ls_param-name = c_param_vkorg.
        lv_vkorg = ls_param-low.
      ENDIF.
    ENDLOOP.
    run( iv_vkorg = lv_vkorg iv_test = abap_false ).
  ENDMETHOD.


  METHOD if_apj_dt_exec_object~get_parameters.
    " TODO: declare the VKORG selection parameter for Application Job Scheduling,
    " e.g. et_parameter_def = VALUE #( ( name = c_param_vkorg
    "                                    ... datatype/length/selname ... ) ).
    " (component names per release - complete in ADT.)
    RETURN.
  ENDMETHOD.

ENDCLASS.
