*"* Local types for behaviour pool ZBP_I_QC_INSP_LOT
*"* -------------------------------------------------------------------------
*"* Paste into the "Class-relevant Local Types" tab, NOT the Global Class tab.
*"* The Global Class tab stays exactly as it is (empty skeleton) - all of the
*"* behaviour lives here.
*"*
*"* Field mappings verified against DD03L and FUPARAREF on 2026-08-21, not
*"* assumed. Three of these bite silently if you guess:
*"*
*"*   BAPI2045D2-MEAN_VALUE is CHAR 22, NOT a float. A numeric result has to
*"*   be rendered as plain decimal text. Formatting an FLTP straight into a
*"*   string template yields scientific notation, which QM rejects.
*"*
*"*   BAPI2045D2-INSPOPER is QIBPVORNR CHAR 4 - the operation NUMBER (VORNR).
*"*   QAMV/QAMR carry VORGLFNR (QLFNKN NUMC 8), the operation node counter.
*"*   They are different numbers. QAPO holds both; oper_number( ) converts.
*"*
*"*   BAPI_INSPCHAR_SETRESULT returns BAPIRETURN1. BAPI_INSPOPER_RECORDRESULTS
*"*   returns BAPIRET2. Different structures, different field names.
*"*
*"* 2026-08-28: the QM BAPIs moved OUT of the action handlers and INTO the
*"* saver. They modify the database, and RAP forbids that during the modify
*"* phase - the runtime raises BEHAVIOR_ILLEGAL_STATEMENT and the whole call
*"* short-dumps. The actions now validate and buffer; save( ) does the work.
*"* This is the documented shape of an unmanaged BO, and it is also why the
*"* saver exists rather than being a formality to satisfy the compiler.
*"*
*"* 2026-09-05 (QC audit): the three follow-on actions the behaviour
*"* definition has declared since 2026-08-28 - releaseToProduction,
*"* confirmDyeing, confirmWinding - are now IMPLEMENTED here. Until this
*"* version the definition declared them, the projection exposed them, the
*"* apps showed the buttons, and the class had no handler: pressing one
*"* short-dumped with "no handler for action". The instance feature control
*"* now switches each of them on only for its own inspection type, only after
*"* a usage decision exists, and only when that decision is accepting.
*"*
*"* WHY THE FOLLOW-ON STEPS ARE THEIR OWN ROUND TRIP
*"* ------------------------------------------------
*"* Save records the results and posts the usage decision. The usage decision
*"* moves the stock out of inspection in its OWN update task. A transfer posted
*"* in that same LUW would read stock that has not moved yet and fail with a
*"* deficit. So all three follow-on actions require a usage decision already on
*"* the database, and the app presents them as a second press after Save.
*"* -------------------------------------------------------------------------


*"* Buffer between the modify phase and the save phase. CLASS-DATA because the
*"* handler and the saver are separate classes and RAP gives us no other way to
*"* hand data from one to the other. Cleared in save( ) and again in cleanup( ),
*"* so a rolled-back request cannot leak its rows into the next one.
CLASS lcl_pending DEFINITION.
  PUBLIC SECTION.

    TYPES: BEGIN OF ty_single,
             lot    TYPE qals-prueflos,
             oper   TYPE vornr,
             char   TYPE qamv-merknr,
             result TYPE bapi2045d2,
           END OF ty_single,
           tt_single TYPE STANDARD TABLE OF ty_single WITH EMPTY KEY.

    TYPES: BEGIN OF ty_confirm,
             lot     TYPE qals-prueflos,
             oper    TYPE vornr,
             results TYPE STANDARD TABLE OF bapi2045d2 WITH EMPTY KEY,
           END OF ty_confirm,
           tt_confirm TYPE STANDARD TABLE OF ty_confirm WITH EMPTY KEY.

    TYPES: BEGIN OF ty_ud,
             lot TYPE qals-prueflos,
             ud  TYPE bapi2045ud,
           END OF ty_ud,
           tt_ud TYPE STANDARD TABLE OF ty_ud WITH EMPTY KEY.

    " Grey QC follow-on: the 301 transfer, RM location to production location.
    TYPES: BEGIN OF ty_release,
             lot     TYPE qals-prueflos,
             matnr   TYPE matnr,
             werks   TYPE werks_d,
             charg   TYPE charg_d,
             to_chrg TYPE charg_d,
             bwart   TYPE bwart,
             lgort   TYPE lgort_d,
             umlgo   TYPE lgort_d,
             menge   TYPE menge_d,
             meins   TYPE meins,
             budat   TYPE budat,
             bktxt   TYPE bktxt,
           END OF ty_release,
           tt_release TYPE STANDARD TABLE OF ty_release WITH EMPTY KEY.

    " Post-Dyeing / Post-Winding follow-on: one operation confirmation.
    TYPES: BEGIN OF ty_prodconf,
             lot     TYPE qals-prueflos,
             aufnr   TYPE aufnr,
             batchno TYPE charg_d,
             gjahr   TYPE gjahr,
             jobno   TYPE zde_jobno,
             vornr   TYPE vornr,
             werks   TYPE werks_d,
             arbpl   TYPE arbpl,
             yield   TYPE ru_lmnga,
             scrap   TYPE ru_xmnga,
             meins   TYPE ru_vorme,
             final   TYPE abap_bool,
             budat   TYPE budat,
             ltxa1   TYPE ltxa1,
             ud_code TYPE qvcode,
             ud_grp  TYPE qvgruppe,
             ud_val  TYPE qbewertung,
           END OF ty_prodconf,
           tt_prodconf TYPE STANDARD TABLE OF ty_prodconf WITH EMPTY KEY.

    CLASS-DATA gt_single   TYPE tt_single.
    CLASS-DATA gt_confirm  TYPE tt_confirm.
    CLASS-DATA gt_ud       TYPE tt_ud.
    CLASS-DATA gt_release  TYPE tt_release.
    CLASS-DATA gt_prodconf TYPE tt_prodconf.

    CLASS-METHODS reset.

ENDCLASS.

CLASS lcl_pending IMPLEMENTATION.
  METHOD reset.
    CLEAR: gt_single, gt_confirm, gt_ud, gt_release, gt_prodconf.
  ENDMETHOD.
ENDCLASS.


CLASS lhc_inspectionlot DEFINITION INHERITING FROM cl_abap_behavior_handler.

  PRIVATE SECTION.
    TYPES ty_failed   TYPE RESPONSE FOR FAILED   EARLY zi_qc_insp_lot.
    TYPES ty_reported TYPE RESPONSE FOR REPORTED EARLY zi_qc_insp_lot.

    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features FOR InspectionLot RESULT result.
    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR InspectionLot
      RESULT result.

    METHODS lock FOR LOCK
      IMPORTING keys FOR LOCK InspectionLot.

    METHODS recordSingleResult FOR MODIFY
      IMPORTING keys FOR ACTION InspectionLot~recordSingleResult RESULT result.

    METHODS recordResults FOR MODIFY
      IMPORTING keys FOR ACTION InspectionLot~recordResults RESULT result.

    METHODS setUsageDecision FOR MODIFY
      IMPORTING keys FOR ACTION InspectionLot~setUsageDecision RESULT result.

    METHODS releaseToProduction FOR MODIFY
      IMPORTING keys FOR ACTION InspectionLot~releaseToProduction RESULT result.

    METHODS confirmDyeing FOR MODIFY
      IMPORTING keys FOR ACTION InspectionLot~confirmDyeing RESULT result.

    METHODS confirmWinding FOR MODIFY
      IMPORTING keys FOR ACTION InspectionLot~confirmWinding RESULT result.

    METHODS read_lot
      IMPORTING iv_lot        TYPE qals-prueflos
      RETURNING VALUE(rs_lot) TYPE zi_qc_insp_lot.

    METHODS oper_number
      IMPORTING iv_lot          TYPE qals-prueflos
                iv_node         TYPE qamv-vorglfnr
      RETURNING VALUE(rv_vornr) TYPE vornr.

    METHODS num_to_char
      IMPORTING iv_value       TYPE f
      RETURNING VALUE(rv_text) TYPE qmean_val.

    " The usage decision as it is on the DATABASE: code, group and QAVE's own
    " valuation. Returns abap_true only for an accepting decision.
    METHODS read_ud
      IMPORTING iv_lot             TYPE qals-prueflos
      EXPORTING ev_code            TYPE qvcode
                ev_grp             TYPE qvgruppe
                ev_val             TYPE qbewertung
      RETURNING VALUE(rv_accepted) TYPE abap_bool.

    " One validation failure: the row goes to failed and its message to
    " reported. Six lines of plumbing otherwise repeated per check.
    METHODS fail
      IMPORTING iv_lot      TYPE qals-prueflos
                iv_text     TYPE string
      CHANGING  cs_failed   TYPE ty_failed
                cs_reported TYPE ty_reported.

    " Shared by both confirmations - they differ only in the operation they
    " post against, and that is the one parameter.
    METHODS buffer_confirmation
      IMPORTING iv_lot        TYPE qals-prueflos
                is_param      TYPE zd_qc_confirm_prod
                iv_default_op TYPE vornr
      CHANGING  cs_failed     TYPE ty_failed
                cs_reported   TYPE ty_reported.

ENDCLASS.


CLASS lhc_inspectionlot IMPLEMENTATION.

  METHOD get_global_authorizations.
    " Flat grant, deliberately. Access is already controlled twice: by the FLP
    " role that reaches the app at all, and by QM's own authority checks inside
    " the BAPIs. A third hand-rolled check here could only diverge from those
    " by accident. Split this per stage when the QC roles are split per stage.
    IF requested_authorizations-%action-recordSingleResult = if_abap_behv=>mk-on.
      result-%action-recordSingleResult = if_abap_behv=>auth-allowed.
    ENDIF.
    IF requested_authorizations-%action-recordResults = if_abap_behv=>mk-on.
      result-%action-recordResults = if_abap_behv=>auth-allowed.
    ENDIF.
    IF requested_authorizations-%action-setUsageDecision = if_abap_behv=>mk-on.
      result-%action-setUsageDecision = if_abap_behv=>auth-allowed.
    ENDIF.
    IF requested_authorizations-%action-releaseToProduction = if_abap_behv=>mk-on.
      result-%action-releaseToProduction = if_abap_behv=>auth-allowed.
    ENDIF.
    IF requested_authorizations-%action-confirmDyeing = if_abap_behv=>mk-on.
      result-%action-confirmDyeing = if_abap_behv=>auth-allowed.
    ENDIF.
    IF requested_authorizations-%action-confirmWinding = if_abap_behv=>mk-on.
      result-%action-confirmWinding = if_abap_behv=>auth-allowed.
    ENDIF.
  ENDMETHOD.


  METHOD lock.
    " The behaviour definition declares "lock master", which strict ( 2 )
    " requires for an entity with modifying operations, and an unmanaged
    " implementation has to provide the lock itself.
    "
    " EQQALS1 is SAP's own lock object on QALS, keyed by PRUEFLOS - verified
    " against DD25L/DD26S rather than assumed. Using it means this service
    " contends with QA11/QA32 correctly instead of quietly writing over a
    " lot someone has open in SAP GUI.
    "
    " _SCOPE is left at its default of '2', so the lock is handed to the
    " update task and released after the COMMIT WORK that RAP issues. That
    " matches how the QM transactions behave.
    LOOP AT keys INTO DATA(ls_key).

      CALL FUNCTION 'ENQUEUE_EQQALS1'
        EXPORTING
          mandant        = sy-mandt
          mode_qals      = 'E'
          prueflos       = ls_key-InspectionLot
        EXCEPTIONS
          foreign_lock   = 1
          system_failure = 2
          OTHERS         = 3.

      IF sy-subrc <> 0.
        " Unlike ACTION/MODIFY key rows, a FOR LOCK key row IS the plain key
        " structure directly - there is no %tky wrapper layer here, since a
        " lock request never needs to carry a data payload alongside the key.
        APPEND VALUE #( %tky = ls_key ) TO failed-inspectionlot.
        APPEND VALUE #( %tky = ls_key
                        %msg = new_message_with_text(
                                 severity = if_abap_behv_message=>severity-error
                                 text     = |Inspection lot { ls_key-InspectionLot } is locked by another user| ) )
               TO reported-inspectionlot.
      ENDIF.

    ENDLOOP.
  ENDMETHOD.


  METHOD recordSingleResult.

    LOOP AT keys INTO DATA(ls_key).

      DATA(ls_p) = ls_key-%param.

      DATA(lv_op) = oper_number( iv_lot  = ls_p-InspectionLot
                                 iv_node = ls_p-OperationNumber ).

      IF lv_op IS INITIAL.
        APPEND VALUE #( %tky = ls_key-%tky ) TO failed-inspectionlot.
        APPEND VALUE #( %tky = ls_key-%tky
                        %msg = new_message_with_text(
                                 severity = if_abap_behv_message=>severity-error
                                 text     = |Operation { ls_p-OperationNumber } not found in lot { ls_p-InspectionLot }| ) )
               TO reported-inspectionlot.
        CONTINUE.
      ENDIF.

      " QAMV-KATALGART1 is filled only for qualitative characteristics, so it
      " is the discriminator. Deciding from "did the UI send us a code" would
      " misfire on a legitimate code of '0'.
      SELECT SINGLE katalgart1 FROM qamv
        WHERE prueflos = @ls_p-InspectionLot
          AND vorglfnr = @ls_p-OperationNumber
          AND merknr   = @ls_p-CharacteristicNumber
        INTO @DATA(lv_catalog).

      IF sy-subrc <> 0.
        " Checked here rather than left to the BAPI: this is the one wrong
        " input the UI can actually produce, and catching it in the modify
        " phase means the technician gets a message naming the row.
        APPEND VALUE #( %tky = ls_key-%tky ) TO failed-inspectionlot.
        APPEND VALUE #( %tky = ls_key-%tky
                        %msg = new_message_with_text(
                                 severity = if_abap_behv_message=>severity-error
                                 text     = |Characteristic { ls_p-CharacteristicNumber } is not in the plan for lot { ls_p-InspectionLot }| ) )
               TO reported-inspectionlot.
        CONTINUE.
      ENDIF.

      DATA(ls_res) = VALUE bapi2045d2( insplot  = ls_p-InspectionLot
                                       inspoper = lv_op
                                       inspchar = ls_p-CharacteristicNumber
                                       closed   = 'X'
                                       remark   = ls_p-ResultComment ).

      IF lv_catalog IS INITIAL.
        ls_res-mean_value = num_to_char( ls_p-MeanValue ).
      ELSE.
        ls_res-code_grp1 = ls_p-ResultCodeGroup.
        ls_res-code1     = ls_p-ResultCode.
      ENDIF.

      " VALID_VALS is the count of values inspected, DEFECTS the count that
      " failed. Both are CHAR 7 in the BAPI, so they are written as text.
      IF ls_p-ActualSampleSize > 0.
        ls_res-valid_vals = |{ ls_p-ActualSampleSize }|.
      ENDIF.
      IF ls_p-DefectCount > 0.
        ls_res-defects = |{ ls_p-DefectCount }|.
      ENDIF.

      " Buffered, not posted. See the header note - the BAPI runs in save( ).
      APPEND VALUE #( lot    = ls_p-InspectionLot
                      oper   = lv_op
                      char   = ls_p-CharacteristicNumber
                      result = ls_res ) TO lcl_pending=>gt_single.

    ENDLOOP.

    result = VALUE #( FOR k IN keys
                      ( %tky   = k-%tky
                        %param = CORRESPONDING #( read_lot( k-%tky-InspectionLot ) ) ) ).

  ENDMETHOD.


  METHOD recordResults.

    DATA lt_res TYPE STANDARD TABLE OF bapi2045d2.

    LOOP AT keys INTO DATA(ls_key).

      DATA(ls_p) = ls_key-%param.

      DATA(lv_op) = oper_number( iv_lot  = ls_p-InspectionLot
                                 iv_node = ls_p-OperationNumber ).

      IF lv_op IS INITIAL.
        APPEND VALUE #( %tky = ls_key-%tky ) TO failed-inspectionlot.
        APPEND VALUE #( %tky = ls_key-%tky
                        %msg = new_message_with_text(
                                 severity = if_abap_behv_message=>severity-error
                                 text     = |Operation { ls_p-OperationNumber } not found in lot { ls_p-InspectionLot }| ) )
               TO reported-inspectionlot.
        CONTINUE.
      ENDIF.

      " Confirm the operation by closing every characteristic on it. Each one
      " is normally closed as it is saved; this is the safety net for a lot
      " where the technician skipped a row and the supervisor confirms anyway.
      SELECT merknr FROM qamv
        WHERE prueflos = @ls_p-InspectionLot
          AND vorglfnr = @ls_p-OperationNumber
        INTO TABLE @DATA(lt_char).

      CLEAR lt_res.

      LOOP AT lt_char INTO DATA(ls_char).
        APPEND VALUE #( insplot  = ls_p-InspectionLot
                        inspoper = lv_op
                        inspchar = ls_char-merknr
                        closed   = 'X'
                        remark   = ls_p-ResultComment ) TO lt_res.
      ENDLOOP.

      APPEND VALUE #( lot     = ls_p-InspectionLot
                      oper    = lv_op
                      results = lt_res ) TO lcl_pending=>gt_confirm.

    ENDLOOP.

    result = VALUE #( FOR k IN keys
                      ( %tky   = k-%tky
                        %param = CORRESPONDING #( read_lot( k-%tky-InspectionLot ) ) ) ).

  ENDMETHOD.


  METHOD setUsageDecision.

    LOOP AT keys INTO DATA(ls_key).

      DATA(ls_p) = ls_key-%param.

      " The plant comes from the lot, never from the UI - a UD posted against
      " the wrong plant's catalog would be accepted and mean nothing.
      SELECT SINGLE werk FROM qals
        WHERE prueflos = @ls_p-InspectionLot
        INTO @DATA(lv_plant).

      DATA(ls_ud) = VALUE bapi2045ud(
                      insplot             = ls_p-InspectionLot
                      ud_selected_set     = ls_p-SelectedSet
                      ud_plant            = lv_plant
                      ud_code_group       = ls_p-CodeGroup
                      ud_code             = ls_p-Code
                      ud_recorded_by_user = sy-uname
                      ud_recorded_on_date = sy-datum
                      ud_recorded_at_time = sy-uzeit
                      ud_text_line        = ls_p-Reason ).

      APPEND VALUE #( lot = ls_p-InspectionLot
                      ud  = ls_ud ) TO lcl_pending=>gt_ud.

    ENDLOOP.

    result = VALUE #( FOR k IN keys
                      ( %tky   = k-%tky
                        %param = CORRESPONDING #( read_lot( k-%tky-InspectionLot ) ) ) ).

  ENDMETHOD.


  METHOD releaseToProduction.
    " Validate and buffer only. Nothing here talks to the database in update
    " task - that is BEHAVIOR_ILLEGAL_STATEMENT outside the save phase.
    "
    " Movement 301 from DRM1 to DPR1, verified against MSEG in plant 2002:
    " the transfer that actually puts yarn on the dyeing floor. It renames the
    " yarn on the way - the supplier batch in DRM1 becomes the production
    " greige lot in DPR1 - so the receiving batch is mandatory.
    LOOP AT keys INTO DATA(ls_key).

      DATA(ls_p)   = ls_key-%param.
      DATA(lv_lot) = ls_key-InspectionLot.

      IF read_ud( lv_lot ) = abap_false.
        fail( EXPORTING iv_lot = lv_lot
                        iv_text = |Post an accepting usage decision on lot { lv_lot } first, then release|
              CHANGING  cs_failed = failed cs_reported = reported ).
        CONTINUE.
      ENDIF.

      IF ls_p-Quantity IS INITIAL OR ls_p-Quantity <= 0.
        fail( EXPORTING iv_lot = lv_lot iv_text = |Enter the quantity to move to production|
              CHANGING  cs_failed = failed cs_reported = reported ).
        CONTINUE.
      ENDIF.

      IF ls_p-FromStorageLocation IS INITIAL OR ls_p-ToStorageLocation IS INITIAL.
        fail( EXPORTING iv_lot = lv_lot iv_text = |Both storage locations are required|
              CHANGING  cs_failed = failed cs_reported = reported ).
        CONTINUE.
      ENDIF.

      IF ls_p-ToBatch IS INITIAL.
        fail( EXPORTING iv_lot = lv_lot iv_text = |Enter the greige lot the yarn is released under|
              CHANGING  cs_failed = failed cs_reported = reported ).
        CONTINUE.
      ENDIF.

      " Material, plant and batch come from the LOT, never from the UI - the
      " parameters carry them for display, but a transfer against a material
      " the lot is not about would be accepted and be wrong.
      SELECT SINGLE matnr, werk, charg, mengeneinh FROM qals
        WHERE prueflos = @lv_lot
        INTO @DATA(ls_lot).
      IF sy-subrc <> 0.
        fail( EXPORTING iv_lot = lv_lot iv_text = |Inspection lot { lv_lot } does not exist|
              CHANGING  cs_failed = failed cs_reported = reported ).
        CONTINUE.
      ENDIF.

      APPEND VALUE #( lot     = lv_lot
                      matnr   = ls_lot-matnr
                      werks   = ls_lot-werk
                      charg   = ls_lot-charg
                      to_chrg = ls_p-ToBatch
                      bwart   = COND #( WHEN ls_p-MovementType IS INITIAL
                                        THEN '301' ELSE ls_p-MovementType )
                      lgort   = ls_p-FromStorageLocation
                      umlgo   = ls_p-ToStorageLocation
                      menge   = ls_p-Quantity
                      meins   = COND #( WHEN ls_p-Unit IS INITIAL
                                        THEN ls_lot-mengeneinh ELSE ls_p-Unit )
                      budat   = COND #( WHEN ls_p-PostingDate IS INITIAL
                                        THEN sy-datum ELSE ls_p-PostingDate )
                      bktxt   = ls_p-HeaderText )
             TO lcl_pending=>gt_release.
    ENDLOOP.

    result = VALUE #( FOR k IN keys
                      ( %tky   = k-%tky
                        %param = CORRESPONDING #( read_lot( k-%tky-InspectionLot ) ) ) ).
  ENDMETHOD.


  METHOD confirmDyeing.
    LOOP AT keys INTO DATA(ls_key).
      buffer_confirmation( EXPORTING iv_lot        = ls_key-InspectionLot
                                     is_param      = ls_key-%param
                                     iv_default_op = '0010'
                           CHANGING  cs_failed     = failed
                                     cs_reported   = reported ).
    ENDLOOP.
    result = VALUE #( FOR k IN keys
                      ( %tky   = k-%tky
                        %param = CORRESPONDING #( read_lot( k-%tky-InspectionLot ) ) ) ).
  ENDMETHOD.


  METHOD confirmWinding.
    LOOP AT keys INTO DATA(ls_key).
      buffer_confirmation( EXPORTING iv_lot        = ls_key-InspectionLot
                                     is_param      = ls_key-%param
                                     iv_default_op = '0020'
                           CHANGING  cs_failed     = failed
                                     cs_reported   = reported ).
    ENDLOOP.
    result = VALUE #( FOR k IN keys
                      ( %tky   = k-%tky
                        %param = CORRESPONDING #( read_lot( k-%tky-InspectionLot ) ) ) ).
  ENDMETHOD.


  METHOD buffer_confirmation.
    " 0010 is dyeing, 0020 is winding; both operations exist in the routing
    " and both are confirmed in 2002 today (read from AFRU, 2026-08-28).
    DATA lv_code TYPE qvcode.
    DATA lv_grp  TYPE qvgruppe.
    DATA lv_val  TYPE qbewertung.

    IF read_ud( EXPORTING iv_lot  = iv_lot
                IMPORTING ev_code = lv_code
                          ev_grp  = lv_grp
                          ev_val  = lv_val ) = abap_false.
      fail( EXPORTING iv_lot = iv_lot
                      iv_text = |Post an accepting usage decision on lot { iv_lot } first, then confirm|
            CHANGING  cs_failed = cs_failed cs_reported = cs_reported ).
      RETURN.
    ENDIF.

    IF is_param-ProductionOrder IS INITIAL.
      fail( EXPORTING iv_lot = iv_lot iv_text = |Lot { iv_lot } is not linked to a production order|
            CHANGING  cs_failed = cs_failed cs_reported = cs_reported ).
      RETURN.
    ENDIF.

    " The batch is not optional. A confirmation puts quantity against one
    " physical batch, and an order here routinely carries five or six.
    IF is_param-PlantBatch IS INITIAL.
      fail( EXPORTING iv_lot = iv_lot iv_text = |Choose which batch of the order is being confirmed|
            CHANGING  cs_failed = cs_failed cs_reported = cs_reported ).
      RETURN.
    ENDIF.

    IF is_param-WorkCentre IS INITIAL.
      fail( EXPORTING iv_lot = iv_lot iv_text = |Enter the work centre the operation was run on|
            CHANGING  cs_failed = cs_failed cs_reported = cs_reported ).
      RETURN.
    ENDIF.

    IF is_param-YieldQuantity < 0 OR is_param-ScrapQuantity < 0.
      fail( EXPORTING iv_lot = iv_lot iv_text = |Quantities cannot be negative|
            CHANGING  cs_failed = cs_failed cs_reported = cs_reported ).
      RETURN.
    ENDIF.

    IF is_param-YieldQuantity IS INITIAL AND is_param-ScrapQuantity IS INITIAL.
      fail( EXPORTING iv_lot = iv_lot iv_text = |Enter a yield or a scrap quantity|
            CHANGING  cs_failed = cs_failed cs_reported = cs_reported ).
      RETURN.
    ENDIF.

    " The plant comes from the lot, not from the UI.
    SELECT SINGLE werk FROM qals
      WHERE prueflos = @iv_lot
      INTO @DATA(lv_plant).

    DATA lv_aufnr TYPE aufnr.
    lv_aufnr = is_param-ProductionOrder.
    lv_aufnr = |{ lv_aufnr ALPHA = IN }|.

    APPEND VALUE #( lot     = iv_lot
                    aufnr   = lv_aufnr
                    batchno = is_param-PlantBatch
                    gjahr   = COND #( WHEN is_param-PlantBatchYear IS INITIAL
                                      THEN sy-datum(4) ELSE is_param-PlantBatchYear )
                    jobno   = is_param-JobCard
                    vornr   = COND #( WHEN is_param-Operation IS INITIAL
                                      THEN iv_default_op ELSE is_param-Operation )
                    werks   = lv_plant
                    arbpl   = is_param-WorkCentre
                    yield   = is_param-YieldQuantity
                    scrap   = is_param-ScrapQuantity
                    meins   = is_param-Unit
                    final   = xsdbool( is_param-FinalConfirmation = 'X' )
                    budat   = COND #( WHEN is_param-PostingDate IS INITIAL
                                      THEN sy-datum ELSE is_param-PostingDate )
                    ltxa1   = is_param-ConfirmationText
                    ud_code = lv_code
                    ud_grp  = lv_grp
                    ud_val  = lv_val )
           TO lcl_pending=>gt_prodconf.
  ENDMETHOD.


  METHOD fail.
    APPEND VALUE #( %tky = VALUE #( InspectionLot = iv_lot ) ) TO cs_failed-inspectionlot.
    APPEND VALUE #( %tky = VALUE #( InspectionLot = iv_lot )
                    %msg = new_message_with_text(
                             severity = if_abap_behv_message=>severity-error
                             text     = iv_text ) ) TO cs_reported-inspectionlot.
  ENDMETHOD.


  METHOD read_ud.
    " QAVE-VBEWERTUNG carries the usage decision's valuation, so there is no
    " need to know which codes accept - the decision already says. The same
    " fact used to be written down in the ZQC-UD catalogue, in the apps and
    " in this class, and two of the three were free to drift.
    "
    " A database read on purpose. A decision still sitting in this request
    " has not posted its stock yet, and every follow-on step depends on stock
    " that has moved.
    CLEAR: ev_code, ev_grp, ev_val.
    SELECT SINGLE vcode, vcodegrp, vbewertung
      FROM qave
      WHERE prueflos = @iv_lot
      INTO ( @ev_code, @ev_grp, @ev_val ).
    rv_accepted = xsdbool( sy-subrc = 0 AND ev_val = 'A' ).
  ENDMETHOD.


  METHOD read_lot.
    " rs_lot is TYPE zi_qc_insp_lot - the CDS view's own generated ABAP
    " structure - so a plain INTO is exact, no field-by-field mapping needed.
    SELECT SINGLE FROM zi_qc_insp_lot
      FIELDS *
      WHERE InspectionLot = @iv_lot
      INTO @rs_lot.
  ENDMETHOD.


  METHOD get_instance_features.

    TYPES: BEGIN OF ty_ud_row,
             prueflos   TYPE qave-prueflos,
             vbewertung TYPE qave-vbewertung,
           END OF ty_ud_row.

    DATA lt_lot       TYPE STANDARD TABLE OF zi_qc_insp_lot.
    DATA lt_ud        TYPE STANDARD TABLE OF ty_ud_row.
    DATA lv_confirmed TYPE abap_bool.
    DATA lv_decided   TYPE abap_bool.
    DATA lv_accepted  TYPE abap_bool.
    DATA lv_type      TYPE qals-art.

    " FOR ALL ENTRIES over an empty table reads the whole of QALS.
    IF keys IS INITIAL.
      RETURN.
    ENDIF.

    " This BO is unmanaged and declares no read, so READ ENTITIES has no
    " handler to call. The status comes straight from the view, the same way
    " read_lot does it everywhere else in this class.
    "
    " STAT34 and STAT35 are already exposed as ResultsConfirmed and
    " UsageDecisionMade - a confirmed operation takes no further results, and a
    " lot that has been decided cannot be decided twice. Switching the buttons
    " off is better than letting the technician press one and meet a raw BAPI
    " error.
    SELECT inspectionlot,
           inspectiontype,
           resultsconfirmed,
           usagedecisionmade
      FROM zi_qc_insp_lot
      FOR ALL ENTRIES IN @keys
      WHERE inspectionlot = @keys-inspectionlot
      INTO CORRESPONDING FIELDS OF TABLE @lt_lot.

    " The follow-on actions need the decision's valuation, which lives on
    " QAVE, not on the lot header.
    SELECT prueflos, vbewertung
      FROM qave
      FOR ALL ENTRIES IN @keys
      WHERE prueflos = @keys-inspectionlot
      INTO TABLE @lt_ud.

    LOOP AT keys ASSIGNING FIELD-SYMBOL(<ls_key>).

      CLEAR: lv_confirmed, lv_decided, lv_accepted, lv_type.

      READ TABLE lt_lot INTO DATA(ls_lot)
           WITH KEY inspectionlot = <ls_key>-InspectionLot.
      IF sy-subrc = 0.
        lv_confirmed = xsdbool( ls_lot-resultsconfirmed  = 'X' ).
        lv_decided   = xsdbool( ls_lot-usagedecisionmade = 'X' ).
        lv_type      = ls_lot-inspectiontype.
      ENDIF.

      READ TABLE lt_ud INTO DATA(ls_ud)
           WITH KEY prueflos = <ls_key>-InspectionLot.
      IF sy-subrc = 0.
        lv_accepted = xsdbool( lv_decided = abap_true AND ls_ud-vbewertung = 'A' ).
      ENDIF.

      " Each follow-on step belongs to one stage: the greige transfer to the
      " incoming lot types 01 and 08, the dyeing confirmation to type 03, the
      " winding confirmation to type 04. And all three need an ACCEPTING
      " usage decision already on the database - see the header note.
      DATA(lv_release) = xsdbool( lv_accepted = abap_true AND ( lv_type = '01' OR lv_type = '08' ) ).
      DATA(lv_dyeing)  = xsdbool( lv_accepted = abap_true AND lv_type = '03' ).
      DATA(lv_winding) = xsdbool( lv_accepted = abap_true AND lv_type = '04' ).

      APPEND VALUE #(
        %tky = <ls_key>-%tky

        %action-recordSingleResult  = COND #( WHEN lv_confirmed = abap_true
                                              THEN if_abap_behv=>fc-o-disabled
                                              ELSE if_abap_behv=>fc-o-enabled )

        %action-recordResults       = COND #( WHEN lv_confirmed = abap_true
                                              THEN if_abap_behv=>fc-o-disabled
                                              ELSE if_abap_behv=>fc-o-enabled )

        %action-setUsageDecision    = COND #( WHEN lv_decided = abap_true
                                              THEN if_abap_behv=>fc-o-disabled
                                              ELSE if_abap_behv=>fc-o-enabled )

        %action-releaseToProduction = COND #( WHEN lv_release = abap_true
                                              THEN if_abap_behv=>fc-o-enabled
                                              ELSE if_abap_behv=>fc-o-disabled )

        %action-confirmDyeing       = COND #( WHEN lv_dyeing = abap_true
                                              THEN if_abap_behv=>fc-o-enabled
                                              ELSE if_abap_behv=>fc-o-disabled )

        %action-confirmWinding      = COND #( WHEN lv_winding = abap_true
                                              THEN if_abap_behv=>fc-o-enabled
                                              ELSE if_abap_behv=>fc-o-disabled )
      ) TO result.

    ENDLOOP.

  ENDMETHOD.


  METHOD oper_number.
    " QAMV/QAMR carry VORGLFNR, the operation node counter (NUMC 8). The QM
    " BAPIs want VORNR, the operation number (CHAR 4). QAPO looked like the
    " bridge between them, but it is DD02L-TABCLASS INTTAB - an internal
    " structure only, never persisted, so it cannot be selected from.
    "
    " BAPI_INSPLOT_GETOPERATIONS returns a lot's operations in exactly the
    " sequence QAMV/QAMR's VORGLFNR counts them, so the counter is simply the
    " 1-based row index into that list - verified against FUPARAREF, not
    " assumed.
    DATA lt_ops TYPE STANDARD TABLE OF bapi2045l2.
    DATA ls_ret TYPE bapireturn1.

    CALL FUNCTION 'BAPI_INSPLOT_GETOPERATIONS'
      EXPORTING
        number        = iv_lot
      IMPORTING
        return        = ls_ret
      TABLES
        inspoper_list = lt_ops.

    IF ls_ret-type NA 'EA'.
      READ TABLE lt_ops INTO DATA(ls_op) INDEX iv_node.
      IF sy-subrc = 0.
        rv_vornr = ls_op-inspoper.
      ENDIF.
    ENDIF.
  ENDMETHOD.


  METHOD num_to_char.
    " BAPI2045D2-MEAN_VALUE is CHAR 22. Going through DECFLOAT34 with
    " NUMBER = RAW gives a plain decimal string with a '.' separator and no
    " thousands marks, which is what QM parses. Formatting the FLTP directly
    " would produce scientific notation and be rejected.
    DATA lv_dec TYPE decfloat34.
    lv_dec  = iv_value.
    rv_text = |{ lv_dec NUMBER = RAW }|.
  ENDMETHOD.

ENDCLASS.


CLASS lsc_zi_qc_insp_lot DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PROTECTED SECTION.
    METHODS save             REDEFINITION.
    METHODS cleanup          REDEFINITION.
    METHODS cleanup_finalize REDEFINITION.
ENDCLASS.

CLASS lsc_zi_qc_insp_lot IMPLEMENTATION.

  METHOD save.
    " This is where the QM BAPIs belong. RAP permits database modification and
    " update-task registration in the save phase and forbids both in the modify
    " phase, which is what BEHAVIOR_ILLEGAL_STATEMENT was telling us.
    "
    " Still no COMMIT WORK, and above all not BAPI_TRANSACTION_COMMIT with
    " DESTINATION 'NONE'. That would run in a separate session and commit that
    " session's LUW, not ours - the results would silently never be written.
    " RAP issues the COMMIT after this method returns.
    "
    " Order matters: results first, then the operation confirmation that closes
    " them, then the usage decision that closes the lot. Reversing any pair
    " makes the later BAPI reject the earlier one's work. The follow-on
    " postings come last and, by construction, never share a request with a
    " usage decision: the handler refuses them until the decision is on the
    " database.

    DATA ls_return TYPE bapireturn1.
    DATA ls_ret    TYPE bapiret2.
    DATA lt_ret    TYPE STANDARD TABLE OF bapiret2.
    DATA lt_res    TYPE STANDARD TABLE OF bapi2045d2.

    LOOP AT lcl_pending=>gt_single INTO DATA(ls_single).

      CLEAR ls_return.

      CALL FUNCTION 'BAPI_INSPCHAR_SETRESULT'
        EXPORTING
          insplot     = ls_single-lot
          inspoper    = ls_single-oper
          inspchar    = ls_single-char
          char_result = ls_single-result
        IMPORTING
          return      = ls_return.

      IF ls_return-type CA 'EA'.
        APPEND VALUE #( %tky = VALUE #( InspectionLot = ls_single-lot )
                        %msg = new_message( id       = ls_return-id
                                            number   = ls_return-number
                                            severity = if_abap_behv_message=>severity-error
                                            v1       = ls_return-message_v1
                                            v2       = ls_return-message_v2
                                            v3       = ls_return-message_v3
                                            v4       = ls_return-message_v4 ) )
               TO reported-inspectionlot.
      ENDIF.

    ENDLOOP.

    LOOP AT lcl_pending=>gt_confirm INTO DATA(ls_confirm).

      CLEAR: ls_ret, lt_ret.
      lt_res = ls_confirm-results.

      CALL FUNCTION 'BAPI_INSPOPER_RECORDRESULTS'
        EXPORTING
          insplot      = ls_confirm-lot
          inspoper     = ls_confirm-oper
        IMPORTING
          return       = ls_ret
        TABLES
          char_results = lt_res
          returntable  = lt_ret.

      IF ls_ret-type CA 'EA'.
        APPEND VALUE #( %tky = VALUE #( InspectionLot = ls_confirm-lot )
                        %msg = new_message( id       = ls_ret-id
                                            number   = ls_ret-number
                                            severity = if_abap_behv_message=>severity-error
                                            v1       = ls_ret-message_v1
                                            v2       = ls_ret-message_v2
                                            v3       = ls_ret-message_v3
                                            v4       = ls_ret-message_v4 ) )
               TO reported-inspectionlot.
      ENDIF.

      LOOP AT lt_ret INTO DATA(ls_row) WHERE type CA 'EA'.
        APPEND VALUE #( %tky = VALUE #( InspectionLot = ls_confirm-lot )
                        %msg = new_message( id       = ls_row-id
                                            number   = ls_row-number
                                            severity = if_abap_behv_message=>severity-error
                                            v1       = ls_row-message_v1
                                            v2       = ls_row-message_v2
                                            v3       = ls_row-message_v3
                                            v4       = ls_row-message_v4 ) )
               TO reported-inspectionlot.
      ENDLOOP.

    ENDLOOP.

    LOOP AT lcl_pending=>gt_ud INTO DATA(ls_ud_row).

      CLEAR ls_return.

      CALL FUNCTION 'BAPI_INSPLOT_SETUSAGEDECISION'
        EXPORTING
          number  = ls_ud_row-lot
          ud_data = ls_ud_row-ud
        IMPORTING
          return  = ls_return.

      IF ls_return-type CA 'EA'.
        APPEND VALUE #( %tky = VALUE #( InspectionLot = ls_ud_row-lot )
                        %msg = new_message( id       = ls_return-id
                                            number   = ls_return-number
                                            severity = if_abap_behv_message=>severity-error
                                            v1       = ls_return-message_v1
                                            v2       = ls_return-message_v2
                                            v3       = ls_return-message_v3
                                            v4       = ls_return-message_v4 ) )
               TO reported-inspectionlot.
      ENDIF.

    ENDLOOP.

    " ---- the greige transfer, RM location to production location -----------
    " Same material, new batch: MOVE_MAT is deliberately left equal to
    " MATERIAL, and MOVE_BATCH carries the production greige lot. GM_CODE 04
    " is the transfer posting (MB1B). BAPI_GOODSMVT_CREATE registers nothing
    " when it returns an error, so an error leaves no half-posted document
    " for the framework to commit.
    LOOP AT lcl_pending=>gt_release INTO DATA(ls_rel).

      DATA(ls_gm_head) = VALUE bapi2017_gm_head_01( pstng_date = ls_rel-budat
                                                    doc_date   = ls_rel-budat
                                                    header_txt = ls_rel-bktxt ).
      DATA lt_gm_item TYPE STANDARD TABLE OF bapi2017_gm_item_create.
      DATA lt_gm_ret  TYPE STANDARD TABLE OF bapiret2.
      DATA lv_matdoc  TYPE bapi2017_gm_head_ret-mat_doc.
      DATA lv_matyear TYPE bapi2017_gm_head_ret-doc_year.
      CLEAR: lt_gm_item, lt_gm_ret, lv_matdoc, lv_matyear.

      APPEND VALUE bapi2017_gm_item_create(
               material   = ls_rel-matnr
               plant      = ls_rel-werks
               stge_loc   = ls_rel-lgort
               batch      = ls_rel-charg
               move_type  = ls_rel-bwart
               entry_qnt  = ls_rel-menge
               entry_uom  = ls_rel-meins
               move_mat   = ls_rel-matnr
               move_plant = ls_rel-werks
               move_stloc = ls_rel-umlgo
               move_batch = ls_rel-to_chrg ) TO lt_gm_item.

      CALL FUNCTION 'BAPI_GOODSMVT_CREATE'
        EXPORTING
          goodsmvt_header  = ls_gm_head
          goodsmvt_code    = VALUE bapi2017_gm_code( gm_code = '04' )
        IMPORTING
          materialdocument = lv_matdoc
          matdocumentyear  = lv_matyear
        TABLES
          goodsmvt_item    = lt_gm_item
          return           = lt_gm_ret.

      LOOP AT lt_gm_ret INTO DATA(ls_gm_msg) WHERE type CA 'EAX'.
        APPEND VALUE #( %tky = VALUE #( InspectionLot = ls_rel-lot )
                        %msg = new_message( id       = ls_gm_msg-id
                                            number   = ls_gm_msg-number
                                            severity = if_abap_behv_message=>severity-error
                                            v1       = ls_gm_msg-message_v1
                                            v2       = ls_gm_msg-message_v2
                                            v3       = ls_gm_msg-message_v3
                                            v4       = ls_gm_msg-message_v4 ) )
               TO reported-inspectionlot.
      ENDLOOP.

      IF lv_matdoc IS NOT INITIAL.
        APPEND VALUE #( %tky = VALUE #( InspectionLot = ls_rel-lot )
                        %msg = new_message_with_text(
                                 severity = if_abap_behv_message=>severity-success
                                 text     = |Material document { lv_matdoc } posted: { ls_rel-menge } { ls_rel-meins } { ls_rel-charg } -> { ls_rel-to_chrg }| ) )
               TO reported-inspectionlot.
      ENDIF.
    ENDLOOP.

    " ---- the dyeing and winding confirmations ------------------------------
    " The same BAPI ZCO11A calls, so these post exactly what ZCO11A posts. The
    " difference is that ZCO11A follows it with BAPI_TRANSACTION_COMMIT and
    " this must not - the RAP framework owns the commit.
    LOOP AT lcl_pending=>gt_prodconf INTO DATA(ls_conf).

      DATA lt_tt   TYPE STANDARD TABLE OF bapi_pp_timeticket.
      DATA lt_cdet TYPE STANDARD TABLE OF bapi_coru_return.
      DATA ls_cret TYPE bapiret1.
      CLEAR: lt_tt, lt_cdet, ls_cret.

      APPEND VALUE bapi_pp_timeticket(
               orderid        = ls_conf-aufnr
               operation      = ls_conf-vornr
               plant          = ls_conf-werks
               work_cntr      = ls_conf-arbpl
               postg_date     = ls_conf-budat
               yield          = ls_conf-yield
               scrap          = ls_conf-scrap
               conf_quan_unit = ls_conf-meins
               fin_conf       = COND #( WHEN ls_conf-final = abap_true THEN 'X' ELSE space )
               conf_text      = ls_conf-ltxa1 ) TO lt_tt.

      " POST_WRONG_ENTRIES = space: nothing posts if the confirmation is wrong.
      " There is one row here, so partial posting has no meaning and silence
      " about a rejected row would be worse than a message.
      CALL FUNCTION 'BAPI_PRODORDCONF_CREATE_TT'
        EXPORTING
          post_wrong_entries = space
          testrun            = space
        IMPORTING
          return             = ls_cret
        TABLES
          timetickets        = lt_tt
          detail_return      = lt_cdet.

      IF ls_cret-type CA 'EAX'.
        APPEND VALUE #( %tky = VALUE #( InspectionLot = ls_conf-lot )
                        %msg = new_message( id       = ls_cret-id
                                            number   = ls_cret-number
                                            severity = if_abap_behv_message=>severity-error
                                            v1       = ls_cret-message_v1
                                            v2       = ls_cret-message_v2
                                            v3       = ls_cret-message_v3
                                            v4       = ls_cret-message_v4 ) )
               TO reported-inspectionlot.
      ENDIF.
      LOOP AT lt_cdet INTO DATA(ls_cd) WHERE type CA 'EAX'.
        APPEND VALUE #( %tky = VALUE #( InspectionLot = ls_conf-lot )
                        %msg = new_message( id       = ls_cd-id
                                            number   = ls_cd-number
                                            severity = if_abap_behv_message=>severity-error
                                            v1       = ls_cd-message_v1
                                            v2       = ls_cd-message_v2
                                            v3       = ls_cd-message_v3
                                            v4       = ls_cd-message_v4 ) )
               TO reported-inspectionlot.
      ENDLOOP.

      " The BAPI writes the generated confirmation number back into TIMETICKETS
      " (BAPI_PP_TIMETICKET-CONF_NO). The counter RMZHL is NOT on that
      " structure - verified in DD03L on 2026-09-05 - it comes back only in
      " DETAIL_RETURN (BAPI_CORU_RETURN-CONF_CNT). A new confirmation number
      " always starts at counter 1, which is the fallback when the detail row
      " is absent. That number plus the batch is the edge AFRU cannot record
      " (AFRU has no batch column), so it goes into ZQC_CONF_BATCH here and
      " nowhere else.
      READ TABLE lt_tt INTO DATA(ls_done) INDEX 1.
      IF sy-subrc = 0 AND ls_done-conf_no IS NOT INITIAL.
        DATA lv_rmzhl TYPE co_rmzhl.
        lv_rmzhl = VALUE #( lt_cdet[ conf_no = ls_done-conf_no ]-conf_cnt OPTIONAL ).
        IF lv_rmzhl IS INITIAL.
          lv_rmzhl = 1.
        ENDIF.
        INSERT zqc_conf_batch FROM @( VALUE #(
                 mandt        = sy-mandt
                 rueck        = ls_done-conf_no
                 rmzhl        = lv_rmzhl
                 aufnr        = ls_conf-aufnr
                 vornr        = ls_conf-vornr
                 werks        = ls_conf-werks
                 batchno      = ls_conf-batchno
                 gjahr        = ls_conf-gjahr
                 jobno        = ls_conf-jobno
                 prueflos     = ls_conf-lot
                 ud_code      = ls_conf-ud_code
                 ud_codegrp   = ls_conf-ud_grp
                 ud_valuation = ls_conf-ud_val
                 lmnga        = ls_conf-yield
                 xmnga        = ls_conf-scrap
                 meinh        = ls_conf-meins
                 budat        = ls_conf-budat
                 ernam        = sy-uname
                 erdat        = sy-datum
                 erzet        = sy-uzeit ) ).

        APPEND VALUE #( %tky = VALUE #( InspectionLot = ls_conf-lot )
                        %msg = new_message_with_text(
                                 severity = if_abap_behv_message=>severity-success
                                 text     = |Confirmation { ls_done-conf_no } posted for batch { ls_conf-batchno }| ) )
               TO reported-inspectionlot.
      ENDIF.
    ENDLOOP.

    lcl_pending=>reset( ).

  ENDMETHOD.


  METHOD cleanup.
    lcl_pending=>reset( ).
  ENDMETHOD.


  METHOD cleanup_finalize.
    lcl_pending=>reset( ).
  ENDMETHOD.

ENDCLASS.
