class ZCL_PICKUPLOAD_DPC_EXT definition
  public
  inheriting from ZCL_PICKUPLOAD_DPC

  create public .

public section.

* ----------------------------------------------------------------------
* SOLSYNCH class, extended 2026-08-29 with the Scan Suite session check
* at the head of CREATE_DEEP_ENTITY (PickSet), which submits
* ZRPT_SALES_UPLOAD and posts the picking.
*
* It now requires a signed-in app user holding the PICK screen.
* SOLSYNCH's own Android scanner is unaffected - it authenticates as
* ISCAN_APP, which ZCL_ZSOL_APP_AUTH lets through by name.
*
* Extended again 02.09.2026 with the company code / plant check, and
* this one was overdue. The version above established a session and
* threw the result away - it proved the caller was signed in and held
* the PICK screen, and then never asked WHERE they were allowed to
* work. Every scope value in this payload comes from the client: the
* sales order in the header, and WERKS and LGORT on every detail row.
* All of them go into GT_DATA, out to memory, and into
* ZRPT_SALES_UPLOAD, which posts them. An operator granted one plant
* could post a picking upload for an order in another company code,
* into any plant, by editing two fields in the request body. Every
* sibling service in this suite had this check; this one did not.
*
* Extended 07.09.2026 with the SOCHG headroom flag: a signed-in user
* holding the Change Sales Order screen may pack a whole lot onto an
* item, up to 10% over the order quantity. The flag goes to ABAP memory
* ('ZSOL_SOCHG') just before the SUBMIT and ZRPT_SALES_UPLOAD_FR
* (POST_BOX) reads it to widen its tolerance; it is freed afterwards.
*
* NOTE FOR WHOEVER MAINTAINS THIS: a vendor re-import of this class will
* silently drop all three. Put the CHECK_REQUEST, REQUIRE_SALES_ORDER,
* REQUIRE_PLANT and ZSOL_SOCHG lines back if that happens.
* ----------------------------------------------------------------------

  methods /IWBEP/IF_MGW_APPL_SRV_RUNTIME~CREATE_DEEP_ENTITY
    redefinition .
  methods /IWBEP/IF_MGW_APPL_SRV_RUNTIME~CREATE_ENTITY
    redefinition .
  methods /IWBEP/IF_MGW_APPL_SRV_RUNTIME~GET_ENTITYSET
    redefinition .
  methods /IWBEP/IF_MGW_APPL_SRV_RUNTIME~GET_EXPANDED_ENTITY
    redefinition .
  methods /IWBEP/IF_MGW_APPL_SRV_RUNTIME~GET_EXPANDED_ENTITYSET
    redefinition .
  methods /IWBEP/IF_MGW_APPL_SRV_RUNTIME~UPDATE_ENTITY
    redefinition .
protected section.

  methods DETAILSSET_CREATE_ENTITY
    redefinition .
  methods PICKSET_CREATE_ENTITY
    redefinition .
  methods PICKSET_GET_ENTITY
    redefinition .
  methods PICKSET_GET_ENTITYSET
    redefinition .
private section.
ENDCLASS.



CLASS ZCL_PICKUPLOAD_DPC_EXT IMPLEMENTATION.


  METHOD /iwbep/if_mgw_appl_srv_runtime~create_deep_entity.

    TYPES: BEGIN OF gw_final,
             chk(1)  TYPE c,
             iconid  TYPE icon-id ,                                      "Box Status
             vbeln   TYPE zpp_pack-vbeln,                                "Sales Document
             posnr   TYPE zpp_pack-posnr,                                "Item
             pklst   TYPE zpp_pack-pklst,                                "Paking List
             boxno   TYPE zpp_pack-boxno,                                "Box No
             werks   TYPE zpp_pack-werks,                                "Plant
             lgort   TYPE zpp_pack-lgort,                                "Stor. Location
             matnr   TYPE zpp_pack-matnr,                                "Material
             maktx   TYPE makt-maktx,                                    "Mat. Desc.
             mergno  TYPE zpp_pack-mergno,                               "Batch
             grade   TYPE zpp_pack-grade,                                "Grade
             psize   TYPE zpp_pack-psize,                                "Size
             ptype   TYPE zpp_pack-ptype,                                "Packing Type
             pdate   TYPE char10, "zpp_pack-pdate,                                "Prod. Date
             spoolno TYPE zpp_pack-spoolno,                              "Spool No
             netwt   TYPE zpp_pack-netwt,                                "Net Weight
             grosswt TYPE zpp_pack-grosswt,                              "Gross Weight
             tarewt  TYPE zpp_pack-tarewt,                               "Tare Weight
             locexp  TYPE zpp_pack-locexp,                               "Loc/Exp
             exidv2  TYPE vekp-exidv2,                                   "Old Box No
             remarks TYPE char100,                                        "Remarks
             gjahr   TYPE zpp_pack-gjahr,                                "Fiscal Year
             uptol   TYPE zpp_pack-netwt,                                "Upper Tol.
             lwtol   TYPE zpp_pack-netwt,                                "Lower Tol.
           END OF gw_final.

    TYPES: BEGIN OF gw_data,
             vbeln   TYPE zpp_pack-vbeln,                                "Sales Document
             posnr   TYPE zpp_pack-posnr,                                "Item
             boxno   TYPE zpp_pack-boxno,                                "Box No
             werks   TYPE zpp_pack-werks,                                "Plant
             lgort   TYPE zpp_pack-lgort,                                "Stor. Location
             matnr   TYPE zpp_pack-matnr,                                "Material
             maktx   TYPE makt-maktx,                                    "Mat. Desc.
             mergno  TYPE zpp_pack-mergno,                               "Batch
             grade   TYPE zpp_pack-grade,                                "Grade
             psize   TYPE zpp_pack-psize,                                "Size
             ptype   TYPE zpp_pack-ptype,                                "Packing Type
             pdate   TYPE char10, "zpp_pack-pdate,                        "Prod. Date
             spoolno TYPE zpp_pack-tpm,                                  "Spool No
             netwt   TYPE char20, "zpp_pack-netwt,                        "Net Weight
             grosswt TYPE char20, "zpp_pack-grosswt,                      "Gross Weight
             tarewt  TYPE char20, "zpp_pack-tarewt,                       "Tare Weight
             locexp  TYPE zpp_pack-locexp,                               "Loc/Exp
             exidv2  TYPE vekp-exidv2,                                   "Old Box No
           END OF gw_data.

    DATA: lr_deep_entity TYPE zcl_pickupload_mpc=>ty_deep_entity,
          gt_data        TYPE TABLE OF gw_data,
          gs_data        TYPE gw_data,
          gs_final       TYPE gw_final.

    DATA : lr_data            TYPE REF TO data,
           lr_data_line       TYPE REF TO data,
           lr_data1           TYPE REF TO data,
           lr_data_line1      TYPE REF TO data,
           lr_data_descr      TYPE REF TO cl_abap_datadescr,
           lr_data_line_descr TYPE REF TO cl_abap_datadescr.

    FIELD-SYMBOLS: <lt_data>      TYPE ANY TABLE,
                   <lt_data_line> TYPE ANY TABLE.

*   Order number in internal format - authorised below and posted below,
*   so the value checked is the value used.
    DATA lv_vbeln TYPE vbeln_va.

*   SOCHG headroom flag for ZRPT_SALES_UPLOAD_FR - see the class comment.
    DATA: lv_sochg   TYPE abap_bool,
          lv_feature TYPE zsol_app_ufct-feature.

*   Scan Suite session check - see the class comment. This submits the
*   picking upload, so it takes a signed-in app user with the Packing
*   List screen. The result is kept this time: RS_SESSION-ORGS is the
*   caller's company codes and plants, and everything below depends on
*   it.
    DATA(ls_session) = zcl_zsol_app_auth=>check_request(
      it_header  = io_tech_request_context->get_request_headers( )
      iv_feature = 'PICK' ).

    CASE iv_entity_set_name.

      WHEN 'PickSet'.

        io_data_provider->read_entry_data(
           IMPORTING es_data = lr_deep_entity ).

*       ----------------------------------------------------------------
*       Company code / plant check, before anything is collected for the
*       posting. See the class comment for what was wrong.
*
*       The sales order is converted to internal format first and the
*       converted value is written back into the payload, so that the
*       order authorised here is the order that goes to
*       ZRPT_SALES_UPLOAD - checking one key and posting another is the
*       shape of bug this exercise keeps turning up.
*
*       Service users - SOLSYNCH's Android scanner - reach this method
*       with an empty grant list, which REQUIRE_SALES_ORDER and
*       REQUIRE_PLANT both read as "no restriction". Nothing changes for
*       that app.
*       ----------------------------------------------------------------
        IF lr_deep_entity-vbeln IS INITIAL.
          RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
            EXPORTING
              textid  = /iwbep/cx_mgw_busi_exception=>business_error
              message = 'No Sales Order supplied'.
        ENDIF.

        lv_vbeln             = |{ lr_deep_entity-vbeln ALPHA = IN }|.
        lr_deep_entity-vbeln = lv_vbeln.

        zcl_zsol_app_auth=>require_sales_order( it_orgs  = ls_session-orgs
                                                iv_vbeln = lv_vbeln ).

        IF lr_deep_entity-picktodetails IS NOT INITIAL.

*         The plant on a detail row is the caller's claim about the box.
*         The ZPP_PACK row is the fact. Both are checked: the claim
*         because it is what actually gets posted, and the fact because
*         a caller who holds the plant they typed but not the plant the
*         box sits in must not be able to pick it.
*
*         The row chosen per box is the one the rest of this suite
*         chooses - not yet on a Challan first, most recent fiscal year
*         first - because ZPP_PACK is keyed BOXNO + GJAHR and a box
*         number is not on its own unique. A scanned pallet number does
*         not appear in ZPP_PACK at all; those rows resolve to nothing
*         here and are covered by the pallet contents check further
*         down.
          SELECT boxno, hupost, gjahr, werks
            FROM zpp_pack
            FOR ALL ENTRIES IN @lr_deep_entity-picktodetails
            WHERE boxno = @lr_deep_entity-picktodetails-boxno
            INTO TABLE @DATA(lt_box_plant).

          SORT lt_box_plant BY boxno ASCENDING hupost ASCENDING gjahr DESCENDING.

          LOOP AT lr_deep_entity-picktodetails INTO DATA(ls_scope).

            zcl_zsol_app_auth=>require_plant( it_orgs  = ls_session-orgs
                                              iv_werks = ls_scope-werks ).

            READ TABLE lt_box_plant INTO DATA(ls_box_plant)
                 WITH KEY boxno = ls_scope-boxno BINARY SEARCH.
            IF sy-subrc = 0.
              zcl_zsol_app_auth=>require_plant( it_orgs  = ls_session-orgs
                                                iv_werks = ls_box_plant-werks ).
            ENDIF.

          ENDLOOP.

        ENDIF.

        IF lr_deep_entity-picktodetails IS NOT INITIAL.
          SELECT pal~palno,
                 pac~boxno,
                 pac~werks,
                 pac~lgort,
                 pac~matnr,
                 mkt~maktx,
                 pac~mergno,
                 pac~grade,
                 pac~psize,
                 pac~ptype,
                 pac~pdate,
                 pac~spoolno,
                 pac~netwt,
                 pac~grosswt,
                 pac~tarewt,
                 pac~locexp,
                 vkp~exidv2
            FROM zpal_cont AS pal
            INNER JOIN zpp_pack AS pac
            ON pal~boxno = pac~boxno
            INNER JOIN vekp AS vkp
            ON pac~exidv = vkp~exidv
            INNER JOIN makt AS mkt
            ON pac~matnr = mkt~matnr
            INTO TABLE @DATA(lt_pal_cont)
            FOR ALL ENTRIES IN @lr_deep_entity-picktodetails
            WHERE pal~palno = @lr_deep_entity-picktodetails-boxno.

        ENDIF.

        LOOP AT lr_deep_entity-picktodetails INTO DATA(wa_picktodetails).

          gs_data-vbeln   = lr_deep_entity-vbeln.
          gs_data-posnr   = wa_picktodetails-posnr.
          gs_data-boxno   = wa_picktodetails-boxno.
          gs_data-werks   = wa_picktodetails-werks.
          gs_data-lgort   = wa_picktodetails-lgort.
          gs_data-matnr   = wa_picktodetails-matnr.
          gs_data-maktx   = wa_picktodetails-arktx.
          gs_data-mergno  = wa_picktodetails-charg.
          gs_data-grade   = wa_picktodetails-zzgrade.
          gs_data-psize   = wa_picktodetails-zzsize.
          gs_data-ptype   = wa_picktodetails-ptype.
          gs_data-pdate   = wa_picktodetails-pdate.
          gs_data-spoolno = wa_picktodetails-spool.
          gs_data-netwt   = wa_picktodetails-netwt.
          gs_data-grosswt = wa_picktodetails-grosswt.
          gs_data-tarewt  = wa_picktodetails-tarewt.
          gs_data-locexp  = wa_picktodetails-locexp.
          gs_data-exidv2  = wa_picktodetails-exidv2.
          APPEND gs_data TO gt_data.

          IF wa_picktodetails-exidv2 IS NOT INITIAL.

            LOOP AT lt_pal_cont INTO DATA(wa_pal_cont) WHERE palno = wa_picktodetails-boxno.

*             A pallet explodes into its own cartons and every one of
*             them is posted. Their plants come from the database rather
*             than from the payload, so authorising the scanned pallet
*             says nothing about them - a pallet whose contents sit in
*             another plant would otherwise walk straight through.
              zcl_zsol_app_auth=>require_plant( it_orgs  = ls_session-orgs
                                                iv_werks = wa_pal_cont-werks ).

              gs_data-vbeln   = lr_deep_entity-vbeln.
              gs_data-posnr   = wa_picktodetails-posnr.
              gs_data-boxno   = wa_pal_cont-boxno.
              gs_data-werks   = wa_pal_cont-werks.
              gs_data-lgort   = wa_pal_cont-lgort.
              gs_data-matnr   = wa_pal_cont-matnr.
              gs_data-maktx   = wa_pal_cont-maktx.
              gs_data-mergno  = wa_pal_cont-mergno.
              gs_data-grade   = wa_pal_cont-grade.
              gs_data-psize   = wa_pal_cont-psize.
              gs_data-ptype   = wa_pal_cont-ptype.
              gs_data-pdate   = wa_pal_cont-pdate.
              gs_data-spoolno = wa_pal_cont-spoolno.
              gs_data-netwt   = wa_pal_cont-netwt.
              gs_data-grosswt = wa_pal_cont-grosswt.
              gs_data-tarewt  = wa_pal_cont-tarewt.
              gs_data-locexp  = wa_pal_cont-locexp.
              gs_data-exidv2  = wa_pal_cont-exidv2.
              APPEND gs_data TO gt_data.

            ENDLOOP.

          ENDIF.

          CLEAR gs_data.
        ENDLOOP.

        EXPORT gt_data FROM gt_data TO MEMORY ID 'ZSOL'.

*       SOCHG headroom (07.09.2026). A signed-in user holding the Change
*       Sales Order screen may pack a whole lot onto an item, up to 10%
*       over the order quantity: ZRPT_SALES_UPLOAD_FR (POST_BOX) widens
*       its tolerance when it finds this flag in memory and behaves as
*       before when it does not. A service user (empty grant list) never
*       gets the flag, so SOLSYNCH's scanner is unchanged. The Packing
*       List screen applies the same rule box by box (capFor), so what
*       the operator was allowed to select is what posts.
        CLEAR lv_sochg.
        IF ls_session-orgs IS NOT INITIAL.
          SELECT SINGLE feature FROM zsol_app_ufct
            WHERE username = @ls_session-username
              AND feature  = 'SOCHG'
            INTO @lv_feature.
          IF sy-subrc = 0.
            lv_sochg = abap_true.
          ENDIF.
        ENDIF.
        EXPORT sochg FROM lv_sochg TO MEMORY ID 'ZSOL_SOCHG'.


        cl_salv_bs_runtime_info=>set(
        EXPORTING display = abap_false
                   metadata = abap_false
                   data  = abap_true ).



        SUBMIT zrpt_sales_upload
          WITH p_chk = 'X' EXPORTING LIST TO MEMORY
          AND RETURN.

*       Unassigned before the read, so a report that produced no list
*       cannot leave the field symbol pointing at anything.
        UNASSIGN: <lt_data>, <lt_data_line>.

        TRY.
            cl_salv_bs_runtime_info=>get_data_ref(
                  IMPORTING
             r_data_descr      = lr_data_descr
             r_data_line_descr = lr_data_line_descr ).
            CREATE DATA lr_data TYPE HANDLE lr_data_descr.
            CREATE DATA lr_data_line TYPE HANDLE lr_data_line_descr.

            ASSIGN lr_data->* TO <lt_data>.
            ASSIGN lr_data_line->* TO <lt_data_line>.

            cl_salv_bs_runtime_info=>get_data(
              IMPORTING
                t_data      = <lt_data>
                t_data_line = <lt_data_line>
                   ).
          CATCH cx_salv_bs_sc_runtime_info.
            UNASSIGN: <lt_data>, <lt_data_line>.
        ENDTRY.

*       The runtime info stays armed until it is cleared. Leaving it set
*       poisons the next SET/GET pair in the same roundtrip.
        cl_salv_bs_runtime_info=>clear_all( ).

        set_etag( iv_value = 'Submitted successfully' ).

        copy_data_to_ref(
                EXPORTING
                  is_data = lr_deep_entity
                CHANGING
                  cr_data = er_deep_entity
                 ).

        FREE MEMORY ID 'ZSOL'.
        FREE MEMORY ID 'ZSOL_SOCHG'.
    ENDCASE.
  ENDMETHOD.


  method /IWBEP/IF_MGW_APPL_SRV_RUNTIME~CREATE_ENTITY.
  endmethod.


  method /IWBEP/IF_MGW_APPL_SRV_RUNTIME~GET_ENTITYSET.
  endmethod.


  method /IWBEP/IF_MGW_APPL_SRV_RUNTIME~GET_EXPANDED_ENTITY.
  endmethod.


  method /IWBEP/IF_MGW_APPL_SRV_RUNTIME~GET_EXPANDED_ENTITYSET.
  endmethod.


  method /IWBEP/IF_MGW_APPL_SRV_RUNTIME~UPDATE_ENTITY.
  endmethod.


  method DETAILSSET_CREATE_ENTITY.
  endmethod.


  method PICKSET_CREATE_ENTITY.
  endmethod.


  method PICKSET_GET_ENTITY.
  endmethod.


  method PICKSET_GET_ENTITYSET.
  endmethod.
ENDCLASS.
