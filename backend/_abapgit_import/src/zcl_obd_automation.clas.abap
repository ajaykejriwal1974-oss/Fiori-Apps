"! <p class="shorttext synchronized">OBD dispatch: pre-checks + 621 packing-material issue</p>
"! Clean-core wrapper for the ZSDOBD / ZSDOBDN dispatch flow (ZSD_OBD_AUTOMATION).
"!
"! DESIGN DECISION: the outbound-delivery creation + handling-unit packing + goods
"! issue stays on the STANDARD delivery transaction/app (VL01N / "Create Outbound
"! Deliveries" / API_OUTBOUND_DELIVERY_SRV). The legacy replays VL01N via BDC precisely
"! because packing pre-existing box-HUs into a delivery and posting GI is what the
"! standard transaction does well - a raw-BAPI rebuild is high-risk (irreversible GI)
"! and typically worse. This class modernises the CUSTOM logic around it:
"!   - validate( )                 : the pre-dispatch gate (HU status, scan status,
"!                                    credit block) - pure reads, safe.
"!   - consume_packing_materials( ): the 621 goods movement that consumes pallet /
"!                                    trolley / bag materials (BAPI_GOODSMVT_CREATE),
"!                                    faithfully ported from FORM bdc_mb11.
"! Call both from the packing/dispatch Fiori app around the standard delivery step.
CLASS zcl_obd_automation DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.

    TYPES tt_pklst TYPE RANGE OF zpp_pack-pklst.
    TYPES tt_ret   TYPE STANDARD TABLE OF bapiret2 WITH DEFAULT KEY.

    "! Pre-dispatch validation gate (no posting).
    "! @parameter ev_ok  | true = all checks passed, dispatch may proceed
    METHODS validate
      IMPORTING iv_vbeln     TYPE vbeln_va
                iv_posnr     TYPE posnr_va
                it_pklst     TYPE tt_pklst
      EXPORTING ev_ok        TYPE abap_bool
      RETURNING VALUE(rt_msg) TYPE tt_ret.

    "! Consume pallet / trolley / bag materials via a 621 goods movement.
    "! @parameter iv_test | true = BAPI_GOODSMVT_CREATE testrun, no posting
    METHODS consume_packing_materials
      IMPORTING iv_vbeln      TYPE vbeln_va
                iv_posnr      TYPE posnr_va
                it_pklst      TYPE tt_pklst
                iv_wadat      TYPE wadat_ist DEFAULT sy-datum
                iv_test       TYPE abap_bool DEFAULT abap_true
      EXPORTING ev_matdoc     TYPE mblnr
                ev_matyear    TYPE mjahr
      RETURNING VALUE(rt_msg) TYPE tt_ret.

  PRIVATE SECTION.
    TYPES: BEGIN OF ty_pallet,
             matnr TYPE matnr,
             menge TYPE zpp_pack-tpqty,
             pklst TYPE zpp_pack-pklst,
           END OF ty_pallet.
    TYPES tt_pallet TYPE STANDARD TABLE OF ty_pallet WITH DEFAULT KEY.

    METHODS collect_pallet
      IMPORTING it_pack          TYPE STANDARD TABLE
      RETURNING VALUE(rt_pallet) TYPE tt_pallet.
    METHODS msg
      IMPORTING iv_type       TYPE bapi_mtype
                iv_text       TYPE clike
      RETURNING VALUE(rs_ret) TYPE bapiret2.
ENDCLASS.


CLASS zcl_obd_automation IMPLEMENTATION.

  METHOD msg.
    rs_ret = VALUE #( type = iv_type id = 'ZOBD' number = '000' message = iv_text ).
  ENDMETHOD.


  METHOD validate.
    ev_ok = abap_true.

    " boxes of this SO / item / packing list(s)
    SELECT * FROM zpp_pack
      WHERE vbeln = @iv_vbeln
        AND posnr = @iv_posnr
        AND pklst IN @it_pklst
        AND pldel = @space
      INTO TABLE @DATA(lt_pack).
    IF lt_pack IS INITIAL.
      APPEND msg( iv_type = 'E' iv_text = |No packing boxes in ZPP_PACK for { iv_vbeln }/{ iv_posnr }| ) TO rt_msg.
      ev_ok = abap_false.
      RETURN.
    ENDIF.

    " resolve external HU id per box (alpha) and read HU status
    DATA lt_exidv TYPE RANGE OF vekp-exidv.
    LOOP AT lt_pack INTO DATA(ls_pk).
      APPEND VALUE #( sign = 'I' option = 'EQ' low = |{ ls_pk-boxno ALPHA = IN }| ) TO lt_exidv.
    ENDLOOP.

    " handling-unit status - must be packed & free (vpobj 12, status 0020, no upper level)
    SELECT exidv, vpobj, uevel, status FROM vekp
      WHERE exidv IN @lt_exidv
      INTO TABLE @DATA(lt_vekp).
    SORT lt_vekp BY exidv.

    LOOP AT lt_pack INTO ls_pk.
      DATA(lv_exidv) = CONV vekp-exidv( |{ ls_pk-boxno ALPHA = IN }| ).
      READ TABLE lt_vekp INTO DATA(ls_vekp) WITH KEY exidv = lv_exidv BINARY SEARCH.
      IF sy-subrc <> 0.
        APPEND msg( iv_type = 'E' iv_text = |Box { ls_pk-boxno } not found in VEKP| ) TO rt_msg.
        ev_ok = abap_false.
      ELSEIF ls_vekp-vpobj <> '12' OR ls_vekp-status <> '0020' OR ls_vekp-uevel IS NOT INITIAL.
        APPEND msg( iv_type = 'E' iv_text = |Invalid HU status for box { ls_pk-boxno }| ) TO rt_msg.
        ev_ok = abap_false.
      ENDIF.
    ENDLOOP.

    " scan status: any box with status 'E-' has not been scanned
    SELECT boxno, status FROM zsol_hudispatch
      FOR ALL ENTRIES IN @lt_pack
      WHERE so = @iv_vbeln AND so_item = @iv_posnr AND boxno = @lt_pack-boxno
      INTO TABLE @DATA(lt_disp).
    LOOP AT lt_disp INTO DATA(ls_disp) WHERE status = 'E-'.
      APPEND msg( iv_type = 'E' iv_text = |Box { ls_disp-boxno } is not scanned| ) TO rt_msg.
      ev_ok = abap_false.
    ENDLOOP.

    " credit block (reuse the existing FM)
    SELECT SINGLE kunnr, kkber FROM vbak WHERE vbeln = @iv_vbeln
      INTO ( @DATA(lv_kunnr), @DATA(lv_kkber) ).
    SELECT SINGLE werks FROM vbap WHERE vbeln = @iv_vbeln AND posnr = @iv_posnr
      INTO @DATA(lv_werks).
    SELECT SINGLE bukrs FROM t001k WHERE bwkey = @lv_werks INTO @DATA(lv_bukrs).
    DATA lv_block TYPE char1.
    CALL FUNCTION 'ZSOL_CREDIT_BLOCK'
      EXPORTING kunnr = lv_kunnr kkber = lv_kkber bukrs = lv_bukrs
      IMPORTING block = lv_block.
    IF lv_block = 'X'.
      APPEND msg( iv_type = 'E' iv_text = 'Credit check has failed' ) TO rt_msg.
      ev_ok = abap_false.
    ENDIF.

    IF ev_ok = abap_true.
      APPEND msg( iv_type = 'S' iv_text = |Dispatch checks passed ({ lines( lt_pack ) } boxes)| ) TO rt_msg.
    ENDIF.
  ENDMETHOD.


  METHOD collect_pallet.
    FIELD-SYMBOLS <pk> TYPE zpp_pack.
    LOOP AT it_pack ASSIGNING <pk>.
      " pallet build-up materials (ptype 03/04), faithful to FORM get_data
      DATA(lt_line) = VALUE tt_pallet(
        ( matnr = <pk>-tpply menge = <pk>-tpqty pklst = <pk>-pklst )
        ( matnr = <pk>-btply menge = <pk>-btqty pklst = <pk>-pklst )
        ( matnr = <pk>-wdply menge = <pk>-wdqty pklst = <pk>-pklst )
        ( matnr = <pk>-plply menge = <pk>-plqty pklst = <pk>-pklst ) ).
      IF <pk>-ptype = '04' AND <pk>-troll IS NOT INITIAL.
        APPEND VALUE #( matnr = <pk>-troll menge = 1 pklst = <pk>-pklst ) TO lt_line.
      ENDIF.
      LOOP AT lt_line INTO DATA(ls_line) WHERE matnr IS NOT INITIAL AND menge IS NOT INITIAL.
        COLLECT ls_line INTO rt_pallet.
      ENDLOOP.
    ENDLOOP.
  ENDMETHOD.


  METHOD consume_packing_materials.
    CLEAR: ev_matdoc, ev_matyear.

    SELECT * FROM zpp_pack
      WHERE vbeln = @iv_vbeln AND posnr = @iv_posnr AND pklst IN @it_pklst AND pldel = @space
      INTO TABLE @DATA(lt_pack).
    DATA(lt_pallet) = collect_pallet( lt_pack ).
    IF lt_pallet IS INITIAL.
      APPEND msg( iv_type = 'S' iv_text = 'No packing materials to consume' ) TO rt_msg.
      RETURN.
    ENDIF.

    " plant + ship-to customer for the 621
    SELECT SINGLE werks FROM vbap WHERE vbeln = @iv_vbeln AND posnr = @iv_posnr INTO @DATA(lv_werks).
    SELECT SINGLE kunnr FROM vbpa
      WHERE vbeln = @( CONV vbeln_va( |{ iv_vbeln ALPHA = IN }| ) ) AND parvw = 'WE'
      INTO @DATA(lv_kunnr).

    DATA(ls_head) = VALUE bapi2017_gm_head_01( pstng_date = iv_wadat
                                               doc_date   = iv_wadat
                                               header_txt = |OBD { iv_vbeln }| ).
    DATA(ls_code) = VALUE bapi2017_gm_code( gm_code = '06' ).
    DATA lt_item TYPE STANDARD TABLE OF bapi2017_gm_item_create.
    LOOP AT lt_pallet INTO DATA(ls_pal).
      APPEND VALUE #( material_long = ls_pal-matnr
                      plant         = lv_werks
                      stge_loc      = 'PAST'
                      move_type     = '621'
                      customer      = lv_kunnr
                      entry_qnt     = ls_pal-menge
                      move_mat_long = ls_pal-matnr
                      move_plant    = lv_werks ) TO lt_item.
    ENDLOOP.

    CALL FUNCTION 'BAPI_GOODSMVT_CREATE'
      EXPORTING  goodsmvt_header  = ls_head
                 goodsmvt_code    = ls_code
                 testrun          = iv_test
      IMPORTING  materialdocument = ev_matdoc
                 matdocumentyear  = ev_matyear
      TABLES     goodsmvt_item    = lt_item
                 return           = rt_msg.

    IF line_exists( rt_msg[ type = 'E' ] ) OR line_exists( rt_msg[ type = 'A' ] ).
      CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.
    ELSEIF iv_test = abap_false AND ev_matdoc IS NOT INITIAL.
      CALL FUNCTION 'BAPI_TRANSACTION_COMMIT' EXPORTING wait = abap_true.
      APPEND msg( iv_type = 'S' iv_text = |Material document { ev_matdoc } posted (621)| ) TO rt_msg.
    ENDIF.
  ENDMETHOD.


  METHOD if_oo_adt_classrun~main.
    out->write( 'ZCL_OBD_AUTOMATION - dispatch wrapper.' ).
    out->write( 'validate( iv_vbeln iv_posnr it_pklst ) -> pre-dispatch gate (no posting).' ).
    out->write( 'consume_packing_materials( ... iv_test ) -> 621 pallet/packing consumption.' ).
    out->write( 'Delivery + HU packing + GI stay on standard (VL01N / Create Outbound Deliveries).' ).
  ENDMETHOD.

ENDCLASS.
