"! <p class="shorttext synchronized">PO creation automation (replaces ZAUTOPO*)</p>
"! Back-to-back PO automation, the clean-core successor to the nine ZAUTOPO*
"! per-company clones (ZPRG_PO_CREATE*). For each sales invoice raised in the
"! main company to a configured intercompany CUSTOMER, it creates the matching
"! purchase order in the configured buying company via BAPI_PO_CREATE1, and
"! logs billing-doc -> PO in ZMM_AUTOPO so nothing is reprocessed.
"!
"! Config ZSOL_AUPO (key BUKRS+EKORG+VKORG) maps: buying company (BUKRS),
"! purch org / plant (EKORG), sales org of the invoices (VKORG), purch group
"! (EKGRP), PO type (BSART), the trigger customer (KUNNR) and the vendor (LIFNR).
"!
"! Field mapping mirrors the live ZPRG_PO_CREATE_6000/7000/... programs (form
"! CREATE_PO), which are the production source of truth:
"!   comp_code = purch_org = plant = the buying company number (e.g. 6000);
"!   pur_group = EKGRP; po item = one per F2 billing item; po_unit = VBRP-VRKME;
"!   tax_code = c_tax_code ('ZY' in legacy); price via a PBXX condition at the
"!   unit rate NETWR/FKIMG with no_price_from_po = 'X'.
"! Billing selection mirrors legacy: FKART='F2', not cancelled (FKSTO/RFBSK/SFAKN).
"!
"! Consolidation PARAMETER = BUKRS (the buying company) - the one class replaces
"! all nine per-company copies. Schedulable via Application Job Scheduling;
"! runnable in ADT (F9, simulation) via if_oo_adt_classrun.
CLASS zcl_po_automation DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.        " run in ADT (console) for test
    INTERFACES if_apj_dt_exec_object.     " Application Job - design time (parameters)
    INTERFACES if_apj_rt_exec_object.     " Application Job - runtime (execute)

    TYPES tt_log TYPE STANDARD TABLE OF string WITH EMPTY KEY.

    "! Create back-to-back POs for one buying company code.
    "! @parameter iv_bukrs | buying company code = ZSOL_AUPO key (the consolidation parameter)
    "! @parameter iv_test  | true = simulate only (no PO, no ZMM_AUTOPO insert)
    "! @parameter rt_log   | per-document processing log
    METHODS run
      IMPORTING iv_bukrs      TYPE bukrs
                iv_test       TYPE abap_bool DEFAULT abap_true
      RETURNING VALUE(rt_log) TYPE tt_log.

  PRIVATE SECTION.
    CONSTANTS c_param_bukrs TYPE string VALUE 'BUKRS' ##NO_TEXT.
    " Item tax code. Legacy ZPRG_PO_CREATE_* hardcodes 'ZY'. CONFIRM with the
    " tax team before go-live; candidate to move into ZSOL_AUPO config.
    CONSTANTS c_tax_code    TYPE mwskz  VALUE 'ZY' ##NO_TEXT.
ENDCLASS.


CLASS zcl_po_automation IMPLEMENTATION.

  METHOD run.
    " 1) config for this buying company (customer/vendor/purch org/plant/PO type)
    SELECT SINGLE * FROM zsol_aupo
      WHERE bukrs = @iv_bukrs
      INTO @DATA(ls_cfg).
    IF sy-subrc <> 0.
      APPEND |No ZSOL_AUPO config for company code { iv_bukrs }| TO rt_log.
      RETURN.
    ENDIF.

    " 2) billing items of this config's trigger customer & sales org, not yet
    "    auto-processed. Filters mirror legacy ZPRG_PO_CREATE_*: F2 invoices
    "    only, not cancelled (FKSTO), not flagged cancelled (RFBSK<>'E'), not a
    "    cancellation doc (SFAKN=space). ZMM_AUTOPO logs ONE PO per billing DOC.
    SELECT k~vbeln, k~waerk, p~posnr, p~matnr, p~fkimg, p~vrkme, p~netwr
      FROM vbrk AS k
      INNER JOIN vbrp AS p ON p~vbeln = k~vbeln
      WHERE k~vkorg = @ls_cfg-vkorg
        AND k~kunag = @ls_cfg-kunnr
        AND k~fkart = 'F2'
        AND k~fksto = @abap_false
        AND k~rfbsk <> 'E'
        AND k~sfakn = @space
        AND p~matnr <> @space
        AND p~fkimg <> 0
        AND NOT EXISTS ( SELECT 1 FROM zmm_autopo AS a
                           WHERE a~vbeln = k~vbeln )
      ORDER BY k~vbeln, p~posnr
      INTO TABLE @DATA(lt_items).

    IF lt_items IS INITIAL.
      APPEND |Company { iv_bukrs } / customer { ls_cfg-kunnr }: nothing to process| TO rt_log.
      RETURN.
    ENDIF.

    " distinct billing documents -> one PO each (carry doc currency)
    TYPES: BEGIN OF ty_doc,
             vbeln TYPE vbeln_vf,
             waerk TYPE waerk,
           END OF ty_doc.
    DATA lt_docs TYPE STANDARD TABLE OF ty_doc.
    lt_docs = VALUE #( FOR w IN lt_items ( vbeln = w-vbeln waerk = w-waerk ) ).
    SORT lt_docs BY vbeln.
    DELETE ADJACENT DUPLICATES FROM lt_docs COMPARING vbeln.

    " 3) one PO per billing document: header from config, items from the billing doc
    LOOP AT lt_docs INTO DATA(ls_doc).
      DATA: ls_header  TYPE bapimepoheader,
            ls_headerx TYPE bapimepoheaderx,
            lt_item    TYPE STANDARD TABLE OF bapimepoitem,
            lt_itemx   TYPE STANDARD TABLE OF bapimepoitemx,
            lt_sched   TYPE STANDARD TABLE OF bapimeposchedule,
            lt_schedx  TYPE STANDARD TABLE OF bapimeposchedulx,
            lt_cond    TYPE STANDARD TABLE OF bapimepocond,
            lt_condx   TYPE STANDARD TABLE OF bapimepocondx,
            lt_return  TYPE STANDARD TABLE OF bapiret2,
            lv_ebeln   TYPE ebeln,
            lv_poitem  TYPE ebelp,
            lv_price   TYPE p LENGTH 15 DECIMALS 4.

      CLEAR: ls_header, ls_headerx, lt_item, lt_itemx, lt_sched, lt_schedx,
             lt_cond, lt_condx, lt_return, lv_ebeln, lv_poitem.

      ls_header  = VALUE #( comp_code = ls_cfg-bukrs
                           doc_type  = ls_cfg-bsart      " legacy hardcodes 'TLOC' - confirm config
                           vendor    = ls_cfg-lifnr
                           purch_org = ls_cfg-ekorg
                           pur_group = ls_cfg-ekgrp
                           currency  = ls_doc-waerk
                           doc_date  = sy-datum ).
      ls_headerx = VALUE #( comp_code = abap_true
                           doc_type  = abap_true
                           vendor    = abap_true
                           purch_org = abap_true
                           pur_group = abap_true
                           currency  = abap_true
                           doc_date  = abap_true ).

      LOOP AT lt_items INTO DATA(ls_it) WHERE vbeln = ls_doc-vbeln.
        lv_poitem = lv_poitem + 10.
        lv_price  = ls_it-netwr / ls_it-fkimg.          " unit rate -> PBXX
        APPEND VALUE #( po_item   = lv_poitem
                        material  = ls_it-matnr
                        plant     = ls_cfg-ekorg         " plant = purch org = comp code (legacy '6000')
                        quantity  = ls_it-fkimg
                        po_unit   = ls_it-vrkme          " sales unit (legacy VRKME)
                        net_price = ls_it-netwr          " full line value (legacy); PBXX drives price
                        tax_code  = c_tax_code ) TO lt_item.
        APPEND VALUE #( po_item   = lv_poitem  po_itemx = abap_true
                        material  = abap_true   plant    = abap_true
                        quantity  = abap_true   po_unit  = abap_true
                        net_price = abap_true   tax_code = abap_true ) TO lt_itemx.
        APPEND VALUE #( po_item       = lv_poitem
                        sched_line    = '0001'
                        delivery_date = sy-datum
                        quantity      = ls_it-fkimg ) TO lt_sched.
        APPEND VALUE #( po_item       = lv_poitem   po_itemx    = abap_true
                        sched_line    = '0001'      sched_linex = abap_true
                        delivery_date = abap_true   quantity    = abap_true ) TO lt_schedx.
        " PBXX gross-price condition at the unit rate (legacy pricing)
        APPEND VALUE #( itm_number = lv_poitem
                        cond_type  = 'PBXX'
                        cond_value = lv_price
                        currency   = ls_doc-waerk
                        change_id  = 'U' ) TO lt_cond.
        APPEND VALUE #( itm_number = lv_poitem
                        cond_type  = abap_true
                        cond_value = abap_true
                        currency   = abap_true
                        change_id  = abap_true ) TO lt_condx.
      ENDLOOP.

      IF iv_test = abap_true.
        APPEND |SIMULATE PO for billing { ls_doc-vbeln } -> company { ls_cfg-bukrs } | &&
               |plant { ls_cfg-ekorg } vendor { ls_cfg-lifnr } type { ls_cfg-bsart } | &&
               |tax { c_tax_code } ({ lines( lt_item ) } item(s))| TO rt_log.
        CONTINUE.
      ENDIF.

      CALL FUNCTION 'BAPI_PO_CREATE1'
        EXPORTING poheader         = ls_header
                  poheaderx        = ls_headerx
                  no_price_from_po = abap_true
        IMPORTING exppurchaseorder = lv_ebeln
        TABLES    return           = lt_return
                  poitem           = lt_item
                  poitemx          = lt_itemx
                  poschedule       = lt_sched
                  poschedulex      = lt_schedx
                  pocond           = lt_cond
                  pocondx          = lt_condx.

      IF lv_ebeln IS INITIAL
         OR line_exists( lt_return[ type = 'E' ] )
         OR line_exists( lt_return[ type = 'A' ] ).
        CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.
        LOOP AT lt_return INTO DATA(ls_ret) WHERE type CA 'EA'.
          APPEND |ERROR billing { ls_doc-vbeln }: { ls_ret-message }| TO rt_log.
        ENDLOOP.
      ELSE.
        CALL FUNCTION 'BAPI_TRANSACTION_COMMIT' EXPORTING wait = abap_true.
        INSERT zmm_autopo FROM @( VALUE #( vbeln = ls_doc-vbeln
                                           posnr = 0
                                           ebeln = lv_ebeln ) ).
        APPEND |CREATED PO { lv_ebeln } for billing { ls_doc-vbeln }| TO rt_log.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.


  METHOD if_oo_adt_classrun~main.
    " Dev/test: simulate every configured buying company.
    SELECT DISTINCT bukrs FROM zsol_aupo INTO TABLE @DATA(lt_bukrs).
    IF lt_bukrs IS INITIAL.
      out->write( 'No ZSOL_AUPO configuration found.' ).
      RETURN.
    ENDIF.
    LOOP AT lt_bukrs INTO DATA(ls_bukrs).
      out->write( |== Company { ls_bukrs-bukrs } (simulation) ==| ).
      DATA(lt_log) = run( iv_bukrs = ls_bukrs-bukrs iv_test = abap_true ).
      LOOP AT lt_log INTO DATA(lv_line).
        out->write( lv_line ).
      ENDLOOP.
    ENDLOOP.
  ENDMETHOD.


  METHOD if_apj_rt_exec_object~execute.
    " Application Job runtime: read the BUKRS parameter, run for real.
    DATA lv_bukrs TYPE bukrs.
    LOOP AT it_parameters INTO DATA(ls_param).
      IF ls_param-selname = c_param_bukrs.
        lv_bukrs = ls_param-low.
      ENDIF.
    ENDLOOP.
    run( iv_bukrs = lv_bukrs iv_test = abap_false ).
  ENDMETHOD.


  METHOD if_apj_dt_exec_object~get_parameters.
    " Declare the BUKRS single-value parameter for Application Job Scheduling.
    et_parameter_def = VALUE #(
      ( selname        = c_param_bukrs
        kind           = if_apj_dt_exec_object=>parameter
        datatype       = 'CHAR'
        length         = 4
        param_text     = 'Buying Company Code'
        changeable_ind = abap_true
        mandatory_ind  = abap_true ) ).
  ENDMETHOD.

ENDCLASS.
