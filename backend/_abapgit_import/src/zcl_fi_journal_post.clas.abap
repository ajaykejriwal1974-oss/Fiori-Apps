"! <p class="shorttext synchronized">FI journal posting service (BAPI_ACC_DOCUMENT_POST)</p>
"! Clean-core successor to the four custom FI journal loaders:
"!   ZF02 (ZRFI_BAPI_ACC_DOC_POST), ZSAL_POST (ZFI_BAPI_F_02) - BAPI file uploads;
"!   ZFIEX (ZRPT_BDC_F02), ZFIVT (ZRPT_BDC_F02_NEW)          - BDC F-02 replays.
"! One reusable posting engine over the standard BAPI_ACC_DOCUMENT_POST. The file
"! frontend routes to the standard journal upload / a thin Fiori app; this class is
"! the API-based core (retires the two BDC programs and merges the two BAPI ones).
"!
"! Line account type (GL / customer / vendor) and the debit/credit sign are derived
"! from the posting key via standard config TBSL - no hardcoded posting-key lists.
CLASS zcl_fi_journal_post DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.

    TYPES: BEGIN OF ty_header,
             comp_code  TYPE bukrs,
             doc_date   TYPE bldat,
             pstng_date TYPE budat,
             doc_type   TYPE blart,
             currency   TYPE waers,
             header_txt TYPE bktxt,
             ref_doc_no TYPE xblnr1,
           END OF ty_header.
    TYPES: BEGIN OF ty_item,
             posting_key  TYPE bschl,     " determines GL/customer/vendor + sign (via TBSL)
             account      TYPE hkont,     " GL account / customer / vendor number
             amount       TYPE dmbtr,     " document-currency amount, always positive
             item_text    TYPE sgtxt,
             cost_center  TYPE kostl,
             profit_ctr   TYPE prctr,
             bus_area     TYPE gsber,
             alloc_nmbr   TYPE dzuonr,
             bus_place    TYPE bupla,
             section_code TYPE secco,
             sp_gl_ind    TYPE umskz,
           END OF ty_item.
    TYPES: tt_item   TYPE STANDARD TABLE OF ty_item   WITH DEFAULT KEY,
           tt_return TYPE STANDARD TABLE OF bapiret2  WITH DEFAULT KEY.

    "! Post (or simulate) one accounting document.
    "! @parameter is_header    | document header
    "! @parameter it_item      | line items (posting key + account + amount)
    "! @parameter iv_test      | true = simulate via BAPI_ACC_DOCUMENT_CHECK, no posting
    "! @parameter ev_belnr     | posted document number (blank on error/simulation)
    "! @parameter ev_fisc_year | fiscal year of the posted document
    "! @parameter rt_return    | BAPI messages
    METHODS post
      IMPORTING is_header       TYPE ty_header
                it_item         TYPE tt_item
                iv_test         TYPE abap_bool DEFAULT abap_true
      EXPORTING ev_belnr        TYPE belnr_d
                ev_fisc_year    TYPE gjahr
      RETURNING VALUE(rt_return) TYPE tt_return.

  PRIVATE SECTION.
    TYPES: BEGIN OF ty_bsl,
             bschl TYPE bschl,
             koart TYPE koart,
             shkzg TYPE shkzg,
           END OF ty_bsl.
    DATA mt_bsl TYPE HASHED TABLE OF ty_bsl WITH UNIQUE KEY bschl.

    "! Classify a posting key via TBSL: account type (D/K/S) + credit flag.
    METHODS classify
      IMPORTING iv_bschl  TYPE bschl
      EXPORTING ev_koart  TYPE koart
                ev_credit TYPE abap_bool.
    METHODS alpha
      IMPORTING iv_in         TYPE clike
      RETURNING VALUE(rv_out) TYPE hkont.
ENDCLASS.


CLASS zcl_fi_journal_post IMPLEMENTATION.

  METHOD classify.
    CLEAR: ev_koart, ev_credit.
    READ TABLE mt_bsl INTO DATA(ls_bsl) WITH KEY bschl = iv_bschl.
    IF sy-subrc <> 0.
      SELECT SINGLE koart, shkzg FROM tbsl
        WHERE bschl = @iv_bschl
        INTO ( @ls_bsl-koart, @ls_bsl-shkzg ).
      ls_bsl-bschl = iv_bschl.
      INSERT ls_bsl INTO TABLE mt_bsl.
    ENDIF.
    ev_koart  = ls_bsl-koart.
    ev_credit = xsdbool( ls_bsl-shkzg = 'H' ).       " H = credit -> negative amount
  ENDMETHOD.


  METHOD alpha.
    rv_out = iv_in.
    CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
      EXPORTING input  = rv_out
      IMPORTING output = rv_out.
  ENDMETHOD.


  METHOD post.
    CLEAR: ev_belnr, ev_fisc_year.

    DATA: ls_header TYPE bapiache09,
          lt_gl     TYPE STANDARD TABLE OF bapiacgl09,
          lt_ar     TYPE STANDARD TABLE OF bapiacar09,
          lt_ap     TYPE STANDARD TABLE OF bapiacap09,
          lt_cur    TYPE STANDARD TABLE OF bapiaccr09,
          lv_objkey TYPE bapiache09-obj_key,
          lv_itemno TYPE posnr_acc.

    ls_header = VALUE #( username   = sy-uname
                         bus_act    = 'RFBU'
                         comp_code  = is_header-comp_code
                         doc_date   = is_header-doc_date
                         pstng_date = is_header-pstng_date
                         doc_type   = is_header-doc_type
                         header_txt = is_header-header_txt
                         ref_doc_no = is_header-ref_doc_no ).

    LOOP AT it_item INTO DATA(ls_it).
      lv_itemno = lv_itemno + 1.
      classify( EXPORTING iv_bschl = ls_it-posting_key
                IMPORTING ev_koart = DATA(lv_koart)
                          ev_credit = DATA(lv_credit) ).

      CASE lv_koart.
        WHEN 'S'.                                    " G/L account
          APPEND VALUE #( itemno_acc = lv_itemno
                          gl_account = alpha( ls_it-account )
                          item_text  = ls_it-item_text
                          costcenter = ls_it-cost_center
                          profit_ctr = alpha( ls_it-profit_ctr )
                          bus_area   = ls_it-bus_area
                          alloc_nmbr = ls_it-alloc_nmbr ) TO lt_gl.
        WHEN 'D'.                                    " customer
          APPEND VALUE #( itemno_acc  = lv_itemno
                          customer    = alpha( ls_it-account )
                          item_text   = ls_it-item_text
                          profit_ctr  = alpha( ls_it-profit_ctr )
                          bus_area    = ls_it-bus_area
                          alloc_nmbr  = ls_it-alloc_nmbr
                          sectioncode = ls_it-section_code
                          sp_gl_ind   = ls_it-sp_gl_ind ) TO lt_ar.
        WHEN 'K'.                                    " vendor
          APPEND VALUE #( itemno_acc    = lv_itemno
                          vendor_no     = alpha( ls_it-account )
                          item_text     = ls_it-item_text
                          profit_ctr    = alpha( ls_it-profit_ctr )
                          bus_area      = ls_it-bus_area
                          alloc_nmbr    = ls_it-alloc_nmbr
                          sectioncode   = ls_it-section_code
                          businessplace = ls_it-bus_place
                          sp_gl_ind     = ls_it-sp_gl_ind ) TO lt_ap.
        WHEN OTHERS.
          APPEND VALUE #( type = 'E' id = 'ZFI' number = '000'
                          message = |Posting key { ls_it-posting_key } not found in TBSL| )
                 TO rt_return.
          RETURN.
      ENDCASE.

      APPEND VALUE #( itemno_acc = lv_itemno
                      currency   = is_header-currency
                      amt_doccur = COND #( WHEN lv_credit = abap_true
                                           THEN ls_it-amount * -1
                                           ELSE ls_it-amount ) ) TO lt_cur.
    ENDLOOP.

    IF iv_test = abap_true.
      CALL FUNCTION 'BAPI_ACC_DOCUMENT_CHECK'
        EXPORTING documentheader    = ls_header
        TABLES    accountgl         = lt_gl
                  accountreceivable = lt_ar
                  accountpayable    = lt_ap
                  currencyamount    = lt_cur
                  return            = rt_return.
      RETURN.
    ENDIF.

    CALL FUNCTION 'BAPI_ACC_DOCUMENT_POST'
      EXPORTING documentheader    = ls_header
      IMPORTING obj_key           = lv_objkey
      TABLES    accountgl         = lt_gl
                accountreceivable = lt_ar
                accountpayable    = lt_ap
                currencyamount    = lt_cur
                return            = rt_return.

    IF line_exists( rt_return[ type = 'E' ] )
       OR line_exists( rt_return[ type = 'A' ] ).
      CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.
    ELSE.
      CALL FUNCTION 'BAPI_TRANSACTION_COMMIT' EXPORTING wait = abap_true.
      ev_belnr     = lv_objkey+0(10).                " obj_key = BELNR(10) BUKRS(4) GJAHR(4)
      ev_fisc_year = lv_objkey+14(4).
    ENDIF.
  ENDMETHOD.


  METHOD if_oo_adt_classrun~main.
    " Service class - normally called from an upload app / report / job.
    " Dev smoke test: simulate a tiny two-line G/L document (40 debit / 50 credit)
    " so the mapping + BAPI wiring can be exercised without posting.
    DATA(lt_ret) = post(
      is_header = VALUE #( comp_code  = '1000'
                           doc_date   = sy-datum
                           pstng_date = sy-datum
                           doc_type   = 'SA'
                           currency   = 'INR'
                           header_txt = 'FI journal smoke test'
                           ref_doc_no = 'TEST' )
      it_item   = VALUE #(
        ( posting_key = '40' account = '0000400000' amount = '100.00' item_text = 'Test debit' )
        ( posting_key = '50' account = '0000400000' amount = '100.00' item_text = 'Test credit' ) )
      iv_test   = abap_true ).
    out->write( '== BAPI_ACC_DOCUMENT_CHECK (simulation) ==' ).
    LOOP AT lt_ret INTO DATA(ls_ret).
      out->write( |{ ls_ret-type } { ls_ret-id }{ ls_ret-number } { ls_ret-message }| ).
    ENDLOOP.
    IF lt_ret IS INITIAL.
      out->write( 'No messages - document structure accepted by the BAPI.' ).
    ENDIF.
  ENDMETHOD.

ENDCLASS.
