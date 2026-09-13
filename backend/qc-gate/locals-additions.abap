*&---------------------------------------------------------------------
*& ZBP_I_QC_INSP_LOT - Local Types, additions of 2026-08-28 (rev 2)
*&
*& Three blocks. Paste each where its header says. Not a full replacement:
*& send me the live include and I will fold these in and send back one file.
*&
*& Everything below is now checked against KSD rather than assumed. What
*& changed from rev 1, and why:
*&
*&   is_ud_accepted   QAVE-VBEWERTUNG holds the usage decision's valuation
*&                    directly. The hardcoded list of accepting codes is gone
*&                    - and it was wrong anyway: the accepting codes in
*&                    ZQC-UD are A, A1 and SP, not A1/A2/A3.
*&   movement type    301, not 311. DRM1 "RM Dyg Main St-1" to DPR1 "Dyg Prod
*&                    RM St-1". 311 has been used six times in the plant's
*&                    history; 301 runs every week.
*&   receiving batch  the transfer renames the yarn. The supplier batch in
*&                    DRM1 becomes the production greige lot in DPR1, which is
*&                    what ZPP_BATCHN-LOTNO holds. Without it the yarn lands
*&                    under a batch nothing downstream recognises.
*&   confirmations    no longer blocked. ZCO11A calls BAPI_PRODORDCONF_CREATE_TT
*&                    and then commits - that is the whole posting, there is no
*&                    bespoke logic to factor out. Operation 0010 is dyeing,
*&                    0020 is winding; both already exist in the routing and
*&                    both are being confirmed in 2002 today.
*&   ZPP_CONFIRM      is NOT the confirmation record. COMPONENT holds C0000000xx
*&                    material numbers at 0.1 to 15 kg a row - it is dye and
*&                    chemical consumption per batch. Rev 1 said confirmations
*&                    had to write it. They do not.
*&   ZQC_CONF_BATCH   new. AFRU has no batch column at all, so a posted
*&                    confirmation cannot be traced back to the batch that
*&                    passed. This table is that edge.
*&
*& WHY THE FOLLOW-ON STEPS ARE THEIR OWN ROUND TRIP
*& ------------------------------------------------
*& Save records the results and posts the usage decision. The usage decision
*& moves the stock out of inspection in its OWN update task. A transfer posted
*& in that same LUW would read stock that has not moved yet and fail with a
*& deficit. So all three follow-on actions require a usage decision already on
*& the database, and the app presents them as a second press after Save.
*&---------------------------------------------------------------------


*&---------------------------------------------------------------------
*& BLOCK 1 - into lcl_pending, alongside gt_single / gt_confirm / gt_ud
*&---------------------------------------------------------------------

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

    CLASS-DATA gt_release  TYPE tt_release.
    CLASS-DATA gt_prodconf TYPE tt_prodconf.

*   ... and inside METHOD reset, next to the existing CLEARs:
*       CLEAR gt_release.
*       CLEAR gt_prodconf.


*&---------------------------------------------------------------------
*& BLOCK 2 - into lhc_inspectionlot
*&
*& Declare in the PRIVATE SECTION:
*&   METHODS get_instance_features FOR INSTANCE FEATURES
*&     IMPORTING keys REQUEST requested_features FOR InspectionLot
*&     RESULT result.
*&   METHODS releaseToProduction FOR MODIFY
*&     IMPORTING keys FOR ACTION InspectionLot~releaseToProduction RESULT result.
*&   METHODS confirmDyeing FOR MODIFY
*&     IMPORTING keys FOR ACTION InspectionLot~confirmDyeing RESULT result.
*&   METHODS confirmWinding FOR MODIFY
*&     IMPORTING keys FOR ACTION InspectionLot~confirmWinding RESULT result.
*&   METHODS read_ud IMPORTING iv_lot TYPE qals-prueflos
*&                   EXPORTING ev_code TYPE qvcode
*&                             ev_grp  TYPE qvgruppe
*&                             ev_val  TYPE qbewertung
*&                   RETURNING VALUE(rv_accepted) TYPE abap_bool.
*&---------------------------------------------------------------------

  METHOD read_ud.
*   QAVE-VBEWERTUNG carries the usage decision's valuation, so there is no need
*   to know which codes accept - the decision already says. This is why the
*   hardcoded code list is gone: the same fact was written down in the ZQC-UD
*   catalogue, in Detail.controller.js and in this class, and two of the three
*   were free to drift.
*
*   A database read on purpose. A decision still sitting in this request has
*   not posted its stock yet, and every follow-on step depends on stock that
*   has moved.
    CLEAR: ev_code, ev_grp, ev_val.
    SELECT SINGLE vcode, vcodegrp, vbewertung
      FROM qave
      WHERE prueflos = @iv_lot
      INTO ( @ev_code, @ev_grp, @ev_val ).
    rv_accepted = xsdbool( sy-subrc = 0 AND ev_val = 'A' ).
  ENDMETHOD.


  METHOD get_instance_features.
    READ ENTITIES OF zi_qc_insp_lot IN LOCAL MODE
      ENTITY InspectionLot
        FIELDS ( InspectionType UsageDecisionMade ProductionOrder
                 PlantBatch BatchSource BatchCount OrderSource )
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_lot).

    result = VALUE #( FOR ls IN lt_lot (
      %tky                        = ls-%tky
      %action-releaseToProduction = COND #(
          WHEN ls-InspectionType    NA '01 08'  THEN if_abap_behv=>fc-o-disabled
          WHEN ls-UsageDecisionMade <> 'X'      THEN if_abap_behv=>fc-o-disabled
          WHEN me->read_ud( ls-InspectionLot ) = abap_false
                                                THEN if_abap_behv=>fc-o-disabled
          ELSE if_abap_behv=>fc-o-enabled )
      %action-confirmDyeing       = COND #(
          WHEN ls-InspectionType    <> '03'     THEN if_abap_behv=>fc-o-disabled
          WHEN ls-UsageDecisionMade <> 'X'      THEN if_abap_behv=>fc-o-disabled
          WHEN me->read_ud( ls-InspectionLot ) = abap_false
                                                THEN if_abap_behv=>fc-o-disabled
          ELSE if_abap_behv=>fc-o-enabled )
      %action-confirmWinding      = COND #(
          WHEN ls-InspectionType    <> '04'     THEN if_abap_behv=>fc-o-disabled
          WHEN ls-UsageDecisionMade <> 'X'      THEN if_abap_behv=>fc-o-disabled
          WHEN me->read_ud( ls-InspectionLot ) = abap_false
                                                THEN if_abap_behv=>fc-o-disabled
          ELSE if_abap_behv=>fc-o-enabled )
    ) ).
  ENDMETHOD.


  METHOD releaseToProduction.
*   Validate and buffer only. Nothing here talks to the database in update
*   task - that is BEHAVIOR_ILLEGAL_STATEMENT outside the save phase.
    LOOP AT keys INTO DATA(ls_key).
      DATA(ls_p) = ls_key-%param.

      IF me->read_ud( ls_key-InspectionLot ) = abap_false.
        me->fail( EXPORTING iv_tky = ls_key-%tky
                            iv_txt = 'Save the usage decision first, then release'
                  CHANGING  failed = failed reported = reported ).
        CONTINUE.
      ENDIF.

      IF ls_p-Quantity IS INITIAL OR ls_p-Quantity <= 0.
        me->fail( EXPORTING iv_tky = ls_key-%tky
                            iv_txt = 'Enter the quantity to move to production'
                  CHANGING  failed = failed reported = reported ).
        CONTINUE.
      ENDIF.

      IF ls_p-FromStorageLocation IS INITIAL OR ls_p-ToStorageLocation IS INITIAL.
        me->fail( EXPORTING iv_tky = ls_key-%tky
                            iv_txt = 'Both storage locations are required'
                  CHANGING  failed = failed reported = reported ).
        CONTINUE.
      ENDIF.

*     The receiving batch is the production greige lot the yarn will be dyed
*     under - the one ZPP_BATCHN-LOTNO carries. Blank would post a transfer
*     that keeps the supplier batch, and nothing downstream would find it.
      IF ls_p-ToBatch IS INITIAL.
        me->fail( EXPORTING iv_tky = ls_key-%tky
                            iv_txt = 'Enter the greige lot the yarn is released under'
                  CHANGING  failed = failed reported = reported ).
        CONTINUE.
      ENDIF.

      APPEND VALUE #( lot     = ls_key-InspectionLot
                      matnr   = ls_p-Material
                      werks   = ls_p-Plant
                      charg   = ls_p-Batch
                      to_chrg = ls_p-ToBatch
                      bwart   = COND #( WHEN ls_p-MovementType IS INITIAL
                                        THEN '301' ELSE ls_p-MovementType )
                      lgort   = ls_p-FromStorageLocation
                      umlgo   = ls_p-ToStorageLocation
                      menge   = ls_p-Quantity
                      meins   = ls_p-Unit
                      budat   = COND #( WHEN ls_p-PostingDate IS INITIAL
                                        THEN cl_abap_context_info=>get_system_date( )
                                        ELSE ls_p-PostingDate )
                      bktxt   = ls_p-HeaderText )
             TO lcl_pending=>gt_release.
    ENDLOOP.

    READ ENTITIES OF zi_qc_insp_lot IN LOCAL MODE
      ENTITY InspectionLot ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(lt_out).
    result = VALUE #( FOR ls IN lt_out ( %tky = ls-%tky %param = ls ) ).
  ENDMETHOD.


  METHOD confirmDyeing.
    buffer_confirmation( EXPORTING keys = keys iv_default_op = '0010'
                         CHANGING  failed = failed reported = reported ).
    READ ENTITIES OF zi_qc_insp_lot IN LOCAL MODE
      ENTITY InspectionLot ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(lt_out).
    result = VALUE #( FOR ls IN lt_out ( %tky = ls-%tky %param = ls ) ).
  ENDMETHOD.


  METHOD confirmWinding.
    buffer_confirmation( EXPORTING keys = keys iv_default_op = '0020'
                         CHANGING  failed = failed reported = reported ).
    READ ENTITIES OF zi_qc_insp_lot IN LOCAL MODE
      ENTITY InspectionLot ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(lt_out).
    result = VALUE #( FOR ls IN lt_out ( %tky = ls-%tky %param = ls ) ).
  ENDMETHOD.


* Shared by both confirmations - they differ only in which operation they post
* against, and that is the one parameter. 0010 is dyeing, 0020 is winding;
* both operations exist in the routing and both are confirmed in 2002 today.
  METHOD buffer_confirmation.
    LOOP AT keys INTO DATA(ls_key).
      DATA(ls_p) = ls_key-%param.

      DATA lv_code TYPE qvcode.
      DATA lv_grp  TYPE qvgruppe.
      DATA lv_val  TYPE qbewertung.
      IF me->read_ud( EXPORTING iv_lot  = ls_key-InspectionLot
                      IMPORTING ev_code = lv_code
                                ev_grp  = lv_grp
                                ev_val  = lv_val ) = abap_false.
        me->fail( EXPORTING iv_tky = ls_key-%tky
                            iv_txt = 'Save the usage decision first, then confirm'
                  CHANGING  failed = failed reported = reported ).
        CONTINUE.
      ENDIF.

*     The batch is not optional. A confirmation puts quantity against one
*     physical batch, and an order here routinely carries five or six.
      IF ls_p-PlantBatch IS INITIAL.
        me->fail( EXPORTING iv_tky = ls_key-%tky
                            iv_txt = 'Choose which batch of the order is being confirmed'
                  CHANGING  failed = failed reported = reported ).
        CONTINUE.
      ENDIF.

      IF ls_p-YieldQuantity IS INITIAL AND ls_p-ScrapQuantity IS INITIAL.
        me->fail( EXPORTING iv_tky = ls_key-%tky
                            iv_txt = 'Enter a yield or a scrap quantity'
                  CHANGING  failed = failed reported = reported ).
        CONTINUE.
      ENDIF.

      APPEND VALUE #( lot     = ls_key-InspectionLot
                      aufnr   = ls_p-ProductionOrder
                      batchno = ls_p-PlantBatch
                      gjahr   = ls_p-PlantBatchYear
                      jobno   = ls_p-JobCard
                      vornr   = COND #( WHEN ls_p-Operation IS INITIAL
                                        THEN iv_default_op ELSE ls_p-Operation )
                      werks   = ls_p-Plant
                      arbpl   = ls_p-WorkCentre
                      yield   = ls_p-YieldQuantity
                      scrap   = ls_p-ScrapQuantity
                      meins   = ls_p-Unit
                      final   = xsdbool( ls_p-FinalConfirmation = 'X' )
                      budat   = COND #( WHEN ls_p-PostingDate IS INITIAL
                                        THEN cl_abap_context_info=>get_system_date( )
                                        ELSE ls_p-PostingDate )
                      ltxa1   = ls_p-ConfirmationText
                      ud_code = lv_code
                      ud_grp  = lv_grp
                      ud_val  = lv_val )
             TO lcl_pending=>gt_prodconf.
    ENDLOOP.
  ENDMETHOD.


* Small helper so the four validations above read as validations rather than
* as six lines of message plumbing each.
  METHOD fail.
    APPEND VALUE #( %tky = iv_tky ) TO failed-inspectionlot.
    APPEND VALUE #( %tky = iv_tky
                    %msg = new_message_with_text(
                             severity = if_abap_behv_message=>severity-error
                             text     = iv_txt ) ) TO reported-inspectionlot.
  ENDMETHOD.


*&---------------------------------------------------------------------
*& BLOCK 3 - into lsc_zi_qc_insp_lot~save, AFTER the existing
*&           BAPI_INSPLOT_SETUSAGEDECISION loop
*&
*& Still no COMMIT WORK. The framework commits. Update-task calls are legal
*& here and only here.
*&---------------------------------------------------------------------

*   ---- the greige transfer, RM location to production location -----------
    LOOP AT lcl_pending=>gt_release INTO DATA(ls_rel).
      DATA(ls_gm_head) = VALUE bapi2017_gm_head_01(
                           pstng_date = ls_rel-budat
                           doc_date   = ls_rel-budat
                           header_txt = ls_rel-bktxt ).
*     Same material, new batch: MOVE_MAT is deliberately left equal to
*     MATERIAL, and MOVE_BATCH carries the production greige lot.
      DATA(lt_gm_item) = VALUE bapi2017_gm_item_create_t(
                           ( material    = ls_rel-matnr
                             plant       = ls_rel-werks
                             stge_loc    = ls_rel-lgort
                             batch       = ls_rel-charg
                             move_type   = ls_rel-bwart
                             entry_qnt   = ls_rel-menge
                             entry_uom   = ls_rel-meins
                             move_mat    = ls_rel-matnr
                             move_plant  = ls_rel-werks
                             move_stloc  = ls_rel-umlgo
                             move_batch  = ls_rel-to_chrg ) ).
      DATA lt_gm_ret  TYPE bapiret2_t.
      DATA lv_matdoc  TYPE bapi2017_gm_head_ret-mat_doc.
      DATA lv_matyear TYPE bapi2017_gm_head_ret-doc_year.
      CLEAR: lt_gm_ret, lv_matdoc, lv_matyear.

      CALL FUNCTION 'BAPI_GOODSMVT_CREATE'
        EXPORTING  goodsmvt_header  = ls_gm_head
                   goodsmvt_code    = VALUE bapi2017_gm_code( gm_code = '04' )
        IMPORTING  materialdocument = lv_matdoc
                   matdocumentyear  = lv_matyear
        TABLES     goodsmvt_item    = lt_gm_item
                   return           = lt_gm_ret.

      LOOP AT lt_gm_ret INTO DATA(ls_gm_msg) WHERE type CA 'EAX'.
        APPEND VALUE #( %key = VALUE #( inspectionlot = ls_rel-lot )
                        %msg = new_message( id       = ls_gm_msg-id
                                            number   = ls_gm_msg-number
                                            severity = if_abap_behv_message=>severity-error
                                            v1       = ls_gm_msg-message_v1
                                            v2       = ls_gm_msg-message_v2
                                            v3       = ls_gm_msg-message_v3
                                            v4       = ls_gm_msg-message_v4 ) )
               TO reported-inspectionlot.
      ENDLOOP.

*     BAPI_GOODSMVT_CREATE registers nothing when it returns an error, so an
*     error leaves no half-posted document for the framework to commit.
      IF lv_matdoc IS NOT INITIAL.
        APPEND VALUE #( %key = VALUE #( inspectionlot = ls_rel-lot )
                        %msg = new_message_with_text(
                                 severity = if_abap_behv_message=>severity-success
                                 text     = |Material document { lv_matdoc } posted| ) )
               TO reported-inspectionlot.
      ENDIF.
    ENDLOOP.

*   ---- the dyeing and winding confirmations ------------------------------
*   The same BAPI ZCO11A calls, so these post exactly what ZCO11A posts. The
*   difference is that ZCO11A follows it with BAPI_TRANSACTION_COMMIT and this
*   must not - the RAP framework owns the commit.
    LOOP AT lcl_pending=>gt_prodconf INTO DATA(ls_conf).
      DATA lt_tt     TYPE STANDARD TABLE OF bapi_pp_timeticket.
      DATA lt_cdet   TYPE STANDARD TABLE OF bapi_coru_return.
      DATA ls_cret   TYPE bapiret1.
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
               fin_conf       = COND #( WHEN ls_conf-final = abap_true
                                        THEN 'X' ELSE space )
               conf_text      = ls_conf-ltxa1 ) TO lt_tt.

*     POST_WRONG_ENTRIES = space: nothing posts if the confirmation is wrong.
*     There is one row here, so partial posting has no meaning and silence
*     about a rejected row would be worse than a message.
      CALL FUNCTION 'BAPI_PRODORDCONF_CREATE_TT'
        EXPORTING post_wrong_entries = space
                  testrun            = space
        IMPORTING return             = ls_cret
        TABLES    timetickets        = lt_tt
                  detail_return      = lt_cdet.

      IF ls_cret-type CA 'EAX'.
        APPEND VALUE #( %key = VALUE #( inspectionlot = ls_conf-lot )
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
        APPEND VALUE #( %key = VALUE #( inspectionlot = ls_conf-lot )
                        %msg = new_message( id       = ls_cd-id
                                            number   = ls_cd-number
                                            severity = if_abap_behv_message=>severity-error
                                            v1       = ls_cd-message_v1
                                            v2       = ls_cd-message_v2
                                            v3       = ls_cd-message_v3
                                            v4       = ls_cd-message_v4 ) )
               TO reported-inspectionlot.
      ENDLOOP.

*     The BAPI writes the generated confirmation number back into TIMETICKETS.
*     That number plus the batch is the edge AFRU cannot record, so it goes
*     into ZQC_CONF_BATCH here and nowhere else.
      READ TABLE lt_tt INTO DATA(ls_done) INDEX 1.
      IF sy-subrc = 0 AND ls_done-conf_no IS NOT INITIAL.
        INSERT zqc_conf_batch FROM @( VALUE #(
                 rueck        = ls_done-conf_no
                 rmzhl        = ls_done-conf_cnt
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
                 ernam        = cl_abap_context_info=>get_user_technical_name( )
                 erdat        = cl_abap_context_info=>get_system_date( )
                 erzet        = cl_abap_context_info=>get_system_time( ) ) ).

        APPEND VALUE #( %key = VALUE #( inspectionlot = ls_conf-lot )
                        %msg = new_message_with_text(
                                 severity = if_abap_behv_message=>severity-success
                                 text     = |Confirmation { ls_done-conf_no } posted for batch { ls_conf-batchno }| ) )
               TO reported-inspectionlot.
      ENDIF.
    ENDLOOP.
