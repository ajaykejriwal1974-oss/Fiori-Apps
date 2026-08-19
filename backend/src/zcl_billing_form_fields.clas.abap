"! <p class="shorttext synchronized">Billing invoice custom form fields (eWay + transport)</p>
"! Provides the custom (non-standard) fields the tax-invoice form needs on top of
"! the standard billing data (LBBIL_INVOICE) - the eWay Bill number/date + the
"! transporter/vehicle. This is the exact ZFIELD block the legacy SmartForm
"! (ZRPT_SD_005_NEW) passed as wa_final1, re-sourced from the standard DRC /
"! delivery tables so the S/4 Output Management Billing Document form template can
"! bind them. Call from the Adobe form's Form Data Provider (or the billing-output
"! enrichment BAdI) per billing document.
"!
"! Sources (same as ZCL_EINV_EDOC_BRIDGE=>generate_eway):
"!   eWay no./date/time = J_1IG_EWAYBILL (written by the DRC eWay exit ZEWB_EDOC_TRIGGER);
"!   vehicle no.        = LIKP-ZZTRCKNO (delivery behind the billing doc);
"!   transporter name   = ZTRPTMSTR via LIKP-ZZTRCODE.
CLASS zcl_billing_form_fields DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    "! The 5 custom invoice fields (mirrors DDIC structure ZFIELD).
    TYPES: BEGIN OF ty_fields,
             ebillno   TYPE j_1ig_ebillno,
             egen_dat  TYPE j_1ig_egendat,
             egen_time TYPE j_1ig_egentime,
             zztrckno  TYPE zde_trckno,
             zztrdesc  TYPE zde_trdesc,
           END OF ty_fields.

    "! Custom fields for one billing document (blank where not found).
    "! @parameter iv_vbeln  | billing document (VBRK-VBELN)
    "! @parameter rs_fields | eWay bill no./date/time + vehicle no. + transporter
    METHODS get_custom_fields
      IMPORTING iv_vbeln         TYPE vbeln_vf
      RETURNING VALUE(rs_fields) TYPE ty_fields.
ENDCLASS.


CLASS zcl_billing_form_fields IMPLEMENTATION.

  METHOD get_custom_fields.
    CLEAR rs_fields.

    " 1) eWay bill (DRC) - latest generated row for this billing document
    SELECT ebillno, egen_dat, egen_time
      FROM j_1ig_ewaybill
      WHERE docno   = @iv_vbeln
        AND ebillno <> @space
      ORDER BY erdat DESCENDING, egen_dat DESCENDING
      INTO ( @rs_fields-ebillno, @rs_fields-egen_dat, @rs_fields-egen_time )
      UP TO 1 ROWS.
    ENDSELECT.

    " 2) transport - from the delivery behind the billing document
    SELECT SINGLE vgbel FROM vbrp
      WHERE vbeln = @iv_vbeln AND vgbel <> @space
      INTO @DATA(lv_vgbel).
    IF sy-subrc = 0 AND lv_vgbel IS NOT INITIAL.
      SELECT SINGLE zztrckno, zztrcode FROM likp
        WHERE vbeln = @lv_vgbel
        INTO ( @rs_fields-zztrckno, @DATA(lv_trcode) ).
      IF lv_trcode IS NOT INITIAL.
        SELECT SINGLE zztrdesc FROM ztrptmstr
          WHERE zztrcode = @lv_trcode
          INTO @rs_fields-zztrdesc.
      ENDIF.
    ENDIF.
  ENDMETHOD.

ENDCLASS.
