  METHOD list_chars.
    DATA lv_lot  TYPE c LENGTH 12.
    DATA lv_kind TYPE c LENGTH 1.
    lv_lot  = |{ iv_lot ALPHA = IN }|.
    lv_kind = to_upper( iv_kind ).

    " Stage (D/W) now comes from the CDS view ZC_QC_INSP_CHAR_SCAN, not an ABAP CASE.
    " The kind filter is pushed into the WHERE clause (DB pushdown). A blank kind
    " returns every characteristic, exactly as before.
    SELECT inspectionlot, operationnumber, characteristicnumber, mastercharacteristic,
           characteristicname, characteristickind, characteristicunit, decimalplaces,
           targetvalue, targetisinitial, lowerlimit, lowerlimitisinitial, upperlimit,
           upperlimitisinitial, selectedset, catalogtype, meanvalue, meanisinitial,
           resultcode, resultcodegroup, defectcount, actualsamplesize, valuation,
           inspectorcomment, resultstatus, stage
      FROM zc_qc_insp_char_scan
      WHERE inspectionlot = @lv_lot
        AND ( @lv_kind = ' ' OR stage = @lv_kind )
      ORDER BY operationnumber, characteristicnumber
      INTO TABLE @DATA(lt_db).

    LOOP AT lt_db ASSIGNING FIELD-SYMBOL(<db>).
      APPEND VALUE ts_char(
        inspection_lot        = <db>-inspectionlot
        operation_number      = <db>-operationnumber
        stage                 = <db>-stage
        characteristic_number = <db>-characteristicnumber
        master_characteristic = <db>-mastercharacteristic
        characteristic_name   = <db>-characteristicname
        characteristic_kind   = <db>-characteristickind
        characteristic_unit   = <db>-characteristicunit
        decimal_places        = |{ <db>-decimalplaces }|
        target_value          = q_out( <db>-targetvalue )
        target_is_initial     = <db>-targetisinitial
        lower_limit           = q_out( <db>-lowerlimit )
        lower_is_initial      = <db>-lowerlimitisinitial
        upper_limit           = q_out( <db>-upperlimit )
        upper_is_initial      = <db>-upperlimitisinitial
        selected_set          = <db>-selectedset
        catalog_type          = <db>-catalogtype
        mean_value            = q_out( <db>-meanvalue )
        mean_is_initial       = <db>-meanisinitial
        result_code           = <db>-resultcode
        result_code_group     = <db>-resultcodegroup
        defect_count          = |{ <db>-defectcount }|
        actual_sample_size    = |{ <db>-actualsamplesize }|
        valuation             = <db>-valuation
        inspector_comment     = <db>-inspectorcomment
        result_status         = <db>-resultstatus ) TO rt_chars.
    ENDLOOP.
  ENDMETHOD.
