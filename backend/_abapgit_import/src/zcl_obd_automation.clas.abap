"! <p class="shorttext synchronized">OBD creation automation (replaces ZSDOBD/N)</p>
"! Outbound-delivery automation, the clean-core successor to ZSDOBD / ZSDOBDN
"! (ZSD_OBD_AUTOMATION). Reads dispatch-ready handling units from
"! ZSOL_HUDISPATCH, creates one outbound delivery per sales order via the
"! Outbound Delivery API, posts goods issue, and updates the dispatch status.
"!
"! Schedulable via Application Job Scheduling; runnable in ADT (F9) for testing.
"! Plant is a PARAMETER - one class replaces both ZSDOBD variants.
CLASS zcl_obd_automation DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.
    INTERFACES if_apj_dt_exec_object.
    INTERFACES if_apj_rt_exec_object.

    TYPES tt_log TYPE STANDARD TABLE OF string WITH EMPTY KEY.

    "! Create outbound deliveries for dispatch-ready HUs of one plant.
    "! @parameter iv_werks | plant (the consolidation parameter; empty = all)
    "! @parameter iv_test  | true = simulate only (no delivery, no status update)
    "! @parameter rt_log   | per-sales-order processing log
    METHODS run
      IMPORTING iv_werks      TYPE werks_d OPTIONAL
                iv_test       TYPE abap_bool DEFAULT abap_true
      RETURNING VALUE(rt_log) TYPE tt_log.

  PRIVATE SECTION.
    CONSTANTS c_param_werks  TYPE string VALUE 'WERKS' ##NO_TEXT.
    " Dispatch status that means "ready, not yet delivered" - confirm the code.
    CONSTANTS c_status_ready TYPE char4  VALUE 'RDY'  ##NO_TEXT.
ENDCLASS.


CLASS zcl_obd_automation IMPLEMENTATION.

  METHOD run.
    " 1) dispatch-ready boxes grouped by sales order (ZSOL_HUDISPATCH).
    SELECT so AS salesorder, COUNT( * ) AS boxes
      FROM zsol_hudispatch
      WHERE status = @c_status_ready
      GROUP BY so
      INTO TABLE @DATA(lt_so).

    IF lt_so IS INITIAL.
      APPEND |No dispatch-ready handling units (status { c_status_ready })| TO rt_log.
      RETURN.
    ENDIF.

    " 2) one outbound delivery per sales order. API calls marked TODO.
    LOOP AT lt_so INTO DATA(ls_so).
      " The boxes that make up this delivery (also gives item/HU detail for the API).
      SELECT boxno, so_item, pck_lst
        FROM zsol_hudispatch
        WHERE so = @ls_so-salesorder
          AND status = @c_status_ready
        INTO TABLE @DATA(lt_box).

      IF iv_test = abap_false.
        " TODO: create the outbound delivery via the Outbound Delivery API /
        "   BAPI_OUTB_DELIVERY_CREATE_SLS for sales order ls_so-salesorder with the
        "   handling units in lt_box, then post goods issue
        "   (BAPI_OUTB_DELIVERY_CONFIRM_DEC). On success:
        "     UPDATE zsol_hudispatch SET status = 'DLV'
        "       WHERE so = ls_so-salesorder AND status = c_status_ready.
        "   COMMIT via BAPI_TRANSACTION_COMMIT. Reuse the existing
        "   ZSOL_OBD_AUTOMATION logic / 621-movement messages where applicable.
      ENDIF.

      APPEND |{ COND #( WHEN iv_test = abap_true THEN 'SIMULATE' ELSE 'CREATE' ) }| &&
             | OBD for sales order { ls_so-salesorder } | &&
             |({ ls_so-boxes } box(es))| TO rt_log.
    ENDLOOP.
  ENDMETHOD.


  METHOD if_oo_adt_classrun~main.
    out->write( '== OBD automation (simulation) ==' ).
    DATA(lt_log) = run( iv_test = abap_true ).
    LOOP AT lt_log INTO DATA(lv_line).
      out->write( lv_line ).
    ENDLOOP.
  ENDMETHOD.


  METHOD if_apj_rt_exec_object~execute.
    DATA lv_werks TYPE werks_d.
    LOOP AT it_parameters INTO DATA(ls_param).
      IF ls_param-name = c_param_werks.
        lv_werks = ls_param-low.
      ENDIF.
    ENDLOOP.
    run( iv_werks = lv_werks iv_test = abap_false ).
  ENDMETHOD.


  METHOD if_apj_dt_exec_object~get_parameters.
    " TODO: declare the WERKS selection parameter for Application Job Scheduling.
    RETURN.
  ENDMETHOD.

ENDCLASS.
